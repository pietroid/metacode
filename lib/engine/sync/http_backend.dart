// The client side of a Metacode backend (bin/server.dart), offline first
// (docs/STATE_ARCHITECTURE.md, section 5):
//
// - Down: one SSE stream per app (`GET /sync/<app>`): a snapshot of the
//   user's `remote` fields and `shared`, then deltas, applied by version.
//   Reconnects with backoff; every reconnect starts with a new snapshot.
// - Up: `remote` fields a local action emits are applied at once, kept in
//   the outbox (`.state/outbox.yaml`) and sent (`POST /state/<app>`); they
//   leave it once acknowledged. Pending ones win over snapshots.
// - Remote calls (`POST /call/<app>/<name>`): the outbox goes first; the
//   response's delta is applied before the call completes. Offline, they
//   fail at once with `offline`.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../project_config.dart';
import '../state_bloc.dart';
import '../yaml_writer.dart';
import 'remote_backend.dart';
import 'sse.dart';

class HttpBackend extends RemoteBackend {
  /// The backend's URL, no trailing slash: `https://api.my-own.app`.
  final String url;

  /// The app's module folders: `[]` for the root, `[food]`.
  final List<String> app;

  final StateBloc bloc;

  /// The anonymous user id (shared by the root and its modules).
  final Future<String> userId;

  /// Requests (calls and the outbox); the SSE stream has its own client.
  final http.Client client;

  /// How long to wait before reconnecting, by failed attempt.
  final Duration Function(int attempt) backoff;

  HttpBackend({
    required String url,
    required this.bloc,
    required this.userId,
    this.app = const [],
    http.Client? client,
    this.backoff = defaultBackoff,
  })  : url = url.replaceFirst(RegExp(r'/+$'), ''),
        client = client ?? http.Client();

  /// 0.5s, 1s, 2s... up to 30s.
  static Duration defaultBackoff(int attempt) => Duration(
      milliseconds: (500 * (1 << attempt.clamp(0, 6))).clamp(500, 30000));

  /// `/modules/food` (empty for the root): the app's part of every path.
  String get _appPath => [for (final m in app) '/modules/$m'].join();

  /// The version each field was last set at (by a snapshot, a delta or a
  /// call's response): a change older than that is dropped, so a delta
  /// that arrives after a newer call response (or twice) changes nothing.
  final _fieldVersions = <String, int>{};

  /// Whether the stream is up (a snapshot arrived and it hasn't closed).
  bool get connected => _connected;
  bool _connected = false;

  /// `remote` fields changed here and not yet acknowledged.
  Map<String, dynamic> get outbox => Map.unmodifiable(_outbox);
  final _outbox = <String, dynamic>{};
  Future<void>? _loadingOutbox;

  http.Client? _streamClient;
  StreamSubscription<SseEvent>? _events;
  Timer? _retry;
  int _attempt = 0;
  bool _disposed = false;

  /// Completes when the next snapshot has been applied (for tests).
  Future<void> get synced => _synced.future;
  Completer<void> _synced = Completer<void>();

  @override
  void start() {
    _loadingOutbox = _loadOutbox();
    _connect();
  }

  Future<void> _loadOutbox() async {
    final saved = readYamlDocument(
        await bloc.store?.read(app, file: 'outbox'), 'outbox');
    if (saved != null) _outbox.addAll(saved);
  }

  Future<void> _saveOutbox() async => bloc.store
      ?.write(app, yamlDocument('outbox', _outbox), file: 'outbox');

  Future<Map<String, String>> _headers() async => {
        userHeader: await userId,
        'content-type': 'application/json',
      };

  Future<void> _connect() async {
    if (_disposed) return;
    await _loadingOutbox;
    _streamClient?.close();
    final streamClient = _streamClient = http.Client();
    try {
      final request = http.Request('GET', Uri.parse('$url/sync$_appPath'))
        ..headers.addAll({...await _headers(), 'accept': 'text/event-stream'});
      final response = await streamClient.send(request);
      if (response.statusCode != 200) {
        throw http.ClientException('sync: ${response.statusCode}');
      }
      await _events?.cancel();
      // A broken connection ends the stream (its error is dropped), and
      // the end reconnects.
      _events = parseSse(response.stream.handleError((Object _) {}))
          .listen(_onEvent, onDone: _lost);
    } catch (_) {
      _lost();
    }
  }

  void _lost() {
    _connected = false;
    if (_disposed || (_retry?.isActive ?? false)) return;
    _retry = Timer(backoff(_attempt++), _connect);
  }

  void _onEvent(SseEvent event) {
    final version = (event.data['version'] as num?)?.toInt() ?? 0;
    switch (event.name) {
      case 'snapshot':
        _apply(event.data, version, snapshot: true);
        _connected = true;
        _attempt = 0;
        if (!_synced.isCompleted) _synced.complete();
        _synced = Completer<void>();
        unawaited(_flush());
      case 'delta':
        _apply(event.data, version);
    }
  }

  /// A snapshot or delta's `remote` and `shared` fields over the state
  /// (those newer than what each field has, see [_fieldVersions]; all of
  /// a [snapshot]'s), the outbox on top (a change made here and not yet
  /// sent never flickers back).
  void _apply(Map<String, dynamic> data, int version, {bool snapshot = false}) {
    final scopes = bloc.config.scopes;
    final changes = <String, dynamic>{};
    for (final part in const ['remote', 'shared']) {
      for (final e in ((data[part] as Map?) ?? const {}).entries) {
        final field = e.key.toString();
        if (scopes[field] != part) continue;
        if (!snapshot && version <= (_fieldVersions[field] ?? -1)) continue;
        _fieldVersions[field] = version;
        changes[field] = e.value;
      }
    }
    if (changes.isEmpty) return;
    bloc.setState({...bloc.state, ...changes, ..._outbox});
  }

  @override
  void changed(Map<String, dynamic> fields) {
    _outbox.addAll(fields);
    unawaited(_saveOutbox());
    unawaited(_flush());
  }

  Future<void>? _flushing;

  /// Sends the outbox; the fields still equal to what was sent leave it.
  Future<void> _flush() async {
    if (_flushing != null) {
      await _flushing;
      if (_outbox.isEmpty) return;
    }
    if (!_connected || _outbox.isEmpty) return;
    final done = Completer<void>();
    _flushing = done.future;
    try {
      final sent = jsonDecode(jsonEncode(_outbox)) as Map<String, dynamic>;
      final response = await client.post(Uri.parse('$url/state$_appPath'),
          headers: await _headers(), body: jsonEncode({'fields': sent}));
      if (response.statusCode == 200) {
        for (final e in sent.entries) {
          if (jsonEncode(_outbox[e.key]) == jsonEncode(e.value)) {
            _outbox.remove(e.key);
          }
        }
        await _saveOutbox();
      } else if (response.statusCode == 400) {
        // Rejected (a field it doesn't know, or the wrong type): it would
        // be rejected forever, so it's dropped.
        _outbox.clear();
        await _saveOutbox();
      }
    } catch (_) {
      // Offline: it stays in the outbox until the next connection.
    } finally {
      _flushing = null;
      done.complete();
    }
  }

  @override
  Future<String?> call(String name, Object? value, {String? locale}) async {
    if (!_connected) return 'offline';
    await _flush();
    try {
      final response = await client.post(
          Uri.parse('$url/call$_appPath/$name'),
          headers: await _headers(),
          body: jsonEncode({'value': value, 'locale': locale}));
      final body = jsonDecode(response.body);
      if (body is! Map) return 'failed';
      final error = body['error'];
      if (error is String) return error;
      _apply(Map<String, dynamic>.from(body),
          (body['version'] as num?)?.toInt() ?? 0);
      return null;
    } catch (_) {
      return 'offline';
    }
  }

  @override
  void reconfigure(ProjectConfig config) {}

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _connected = false;
    final client = _streamClient;
    final events = _events;
    if (events == null) {
      client?.close();
    } else {
      events.cancel().whenComplete(() => client?.close());
    }
  }
}

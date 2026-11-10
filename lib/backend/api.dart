// The backend's HTTP API (docs/STATE_ARCHITECTURE.md, section 5), free of
// any server framework: the Dart Frog server (server/routes/) and the shelf
// handler the engine tests serve (handler.dart) both map these replies.
// Every request carries the anonymous user id in the `x-metacode-user`
// header; `<app>` is empty for the root, `/modules/food` for a module.
//
//   GET  /sync<app>              SSE: `snapshot`, then `delta`s
//   POST /state<app>             {fields}         -> {version} | {error}
//   POST /call<app>/<name>       {value, locale}  -> {version, remote?, shared?} | {error}
//
// CORS is open (the web app runs on another origin); the id is a header,
// never in a URL.

import 'dart:async';
import 'dart:convert';

import '../engine/sync/sse.dart';
import 'backend.dart';

export '../engine/sync/sse.dart' show userHeader;

/// What to answer: [status] with a JSON [body], or an SSE [events] stream.
class ApiReply {
  final int status;
  final Map<String, dynamic>? body;
  final Stream<List<int>>? events;

  const ApiReply(this.status, this.body) : events = null;
  const ApiReply.events(Stream<List<int>> this.events)
      : status = 200,
        body = null;

  Map<String, String> get headers => {
        ...corsHeaders,
        if (events != null) ...{
          'content-type': 'text/event-stream',
          'cache-control': 'no-cache',
        } else
          'content-type': 'application/json',
      };

  String? get json => body == null ? null : jsonEncode(body);
}

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, OPTIONS',
  'access-control-allow-headers': 'content-type, $userHeader',
  'access-control-max-age': '86400',
};

/// A user id as the engine makes them (a UUID); anything else is refused,
/// since it names a file.
final _validUserId = RegExp(r'^[A-Za-z0-9-]{8,64}$');

/// The request's user id, or null when it has none or a malformed one.
String? userIdOf(Map<String, String> headers) {
  final id = headers[userHeader];
  return id != null && _validUserId.hasMatch(id) ? id : null;
}

const noUser = ApiReply(401, {'error': 'noUser'});

/// `GET /sync<app>`: the sync stream, with a comment every [ping] so
/// proxies keep it open.
Future<ApiReply> apiSync(MetacodeBackend backend, List<String> app,
    String userId, {Duration ping = const Duration(seconds: 25)}) async {
  final dir = _appDir(app);
  final connection = dir == null ? null : await backend.connect(dir, userId);
  if (connection == null) return const ApiReply(404, {'error': 'unknownApp'});
  return ApiReply.events(_sse(connection, ping));
}

/// `POST /state<app>`: the user's `remote` fields.
Future<ApiReply> apiState(MetacodeBackend backend, List<String> app,
    String userId, String body) async {
  final dir = _appDir(app);
  final fields = _json(body)?['fields'];
  if (dir == null || fields is! Map) {
    return const ApiReply(400, {'error': 'badRequest'});
  }
  final result =
      await backend.pushRemote(dir, userId, Map<String, dynamic>.from(fields));
  return result.error == null
      ? ApiReply(200, {'version': result.version})
      : ApiReply(400, result.toJson());
}

/// `POST /call<app>/<name>`: [path] is the app's segments, then the name.
Future<ApiReply> apiCall(MetacodeBackend backend, List<String> path,
    String userId, String body) async {
  if (path.isEmpty) return const ApiReply(404, {'error': 'unknownAction'});
  final dir = _appDir(path.sublist(0, path.length - 1));
  final json = _json(body);
  if (dir == null || json == null) {
    return const ApiReply(400, {'error': 'badRequest'});
  }
  final result = await backend.call(dir, userId, path.last, json['value']);
  return ApiReply(200, result.toJson());
}

/// `[]` -> `''`, `[modules, food]` -> `modules/food`; null when malformed.
String? _appDir(List<String> segments) {
  segments = [for (final s in segments) if (s.isNotEmpty) s];
  if (segments.length.isOdd) return null;
  for (var i = 0; i < segments.length; i += 2) {
    if (segments[i] != 'modules') return null;
  }
  return segments.join('/');
}

Map<String, dynamic>? _json(String body) {
  try {
    final json = jsonDecode(body);
    return json is Map ? Map<String, dynamic>.from(json) : null;
  } on FormatException {
    return null;
  }
}

Stream<List<int>> _sse(SyncConnection connection, Duration ping) {
  late final StreamController<List<int>> out;
  StreamSubscription<SyncEvent>? events;
  Timer? timer;
  out = StreamController<List<int>>(
    onListen: () {
      events = connection.events.listen(
        (e) => out.add(utf8.encode(sseEvent(e.name, e.data))),
        onDone: out.close,
      );
      timer = Timer.periodic(ping, (_) => out.add(utf8.encode(': ping\n\n')));
    },
    onCancel: () {
      timer?.cancel();
      return events?.cancel();
    },
  );
  return out.stream;
}

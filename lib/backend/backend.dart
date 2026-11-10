// The Metacode backend (docs/STATE_ARCHITECTURE.md, sections 3 and 5): it
// compiles the same project folder as the app and holds, per app (the root
// and each module), its global state:
//
//   system:  <app>/.state/system.yaml        backend only
//   shared:  <app>/.state/shared.yaml        one copy, pushed to everyone
//   users:   <app>/.state/users/<id>.yaml    each user's `remote` fields
//
// in a data folder kept apart from the code ([data]), so pushing code never
// touches data. Remote actions run one at a time per app. Every change is
// pushed to the connected clients that see it ([connect]). Pure Dart: the
// HTTP layer is handler.dart, the process bin/server.dart.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../compiler/build.dart';
import '../compiler/issues.dart';
import '../compiler/models.dart';
import '../compiler/project.dart';
import '../engine/program.dart';
import '../engine/host_plugin.dart';
import '../engine/yaml_writer.dart';
import '../files/project_files.dart';

/// The result of a remote call or a `remote` push: the version and what
/// changed for the caller (null fields: nothing), or an error code.
class BackendResult {
  final int version;
  final Map<String, dynamic>? remote;
  final Map<String, dynamic>? shared;
  final String? error;

  const BackendResult(this.version, {this.remote, this.shared, this.error});
  const BackendResult.error(String this.error)
      : version = 0,
        remote = null,
        shared = null;

  Map<String, dynamic> toJson() => error != null
      ? {'error': error}
      : {'version': version, 'remote': ?remote, 'shared': ?shared};
}

/// One event for a client: `snapshot` or `delta`, with its data.
typedef SyncEvent = ({String name, Map<String, dynamic> data});

/// A client's sync stream (`GET /sync/<app>`), until it closes.
class SyncConnection {
  final String userId;
  final StreamController<SyncEvent> _out;

  SyncConnection._(this.userId, this._out);

  Stream<SyncEvent> get events => _out.stream;

  void _send(String name, Map<String, dynamic> data) {
    if (!_out.isClosed) _out.add((name: name, data: data));
  }
}

class MetacodeBackend {
  /// The project's sources (the root app's folder), watched by the caller:
  /// [reload] after they change.
  final ProjectFiles code;

  /// Repo-relative path of the root app, for the compiler.
  final String path;

  /// Where the state documents are saved (same layout as an app's
  /// `.state/`, modules under `modules/<name>/`).
  final ProjectFiles data;

  MetacodeBackend({required this.code, required this.data, this.path = 'app'});

  final _apps = <String, _App>{};

  /// Increasing across restarts (it starts from the clock), so a client's
  /// versions never go back.
  int _version = DateTime.now().microsecondsSinceEpoch;
  int _next() => ++_version;

  /// The last compile's issues.
  Issues issues = Issues();

  /// Compiles [code] and runs the new version (the state is kept). Returns
  /// whether it compiled; when it doesn't, the old version keeps running.
  bool reload() {
    final result = build(code, path: path);
    issues = result.issues;
    if (result.bundle == null) return false;
    final seen = <String>{};
    for (final app in result.root.tree) {
      seen.add(app.dir);
      final bytes = result.outputs[app.at('.generated/remote_program.evc')];
      final program = bytes is Uint8List
          ? MetacodeProgram(ByteData.sublistView(bytes), {
              'remote': [for (final fn in app.remoteActions) fn.name],
            })
          : null;
      (_apps[app.dir] ??= _App(this, app.dir)).configure(app, program);
    }
    _apps.removeWhere((dir, app) {
      if (seen.contains(dir)) return false;
      app.close();
      return true;
    });
    return true;
  }

  /// The app at [dir] (`''`, `modules/food`), if the project has it.
  _App? _app(String dir) => _apps[dir];

  bool hasApp(String dir) => _apps.containsKey(dir);

  /// Opens a sync stream for [userId] on the app [dir]: a snapshot first
  /// (the user's `remote` fields, or the seeds before their first write,
  /// and `shared`), then every change they see. Null for an unknown app.
  Future<SyncConnection?> connect(String dir, String userId) async {
    final app = _app(dir);
    if (app == null) return null;
    late final SyncConnection connection;
    final out = StreamController<SyncEvent>(
        onCancel: () => app.connections.remove(connection));
    connection = SyncConnection._(userId, out);
    await app.queue(() async {
      connection._send('snapshot', {
        'version': _version,
        'remote': await app.remoteOf(userId),
        'shared': await app.shared(),
      });
      app.connections.add(connection);
    });
    return connection;
  }

  /// A client's `remote` fields (`POST /state/<app>`): each must be a
  /// `remote` field of the right type, or nothing is saved.
  Future<BackendResult> pushRemote(
      String dir, String userId, Map<String, dynamic> fields) async {
    final app = _app(dir);
    if (app == null) return const BackendResult.error('unknownApp');
    final found = Issues();
    for (final e in fields.entries) {
      final type = app.types[e.key];
      if (app.scopes[e.key] != 'remote' || type == null) {
        found.error('state', e.key, 'not a remote field');
      } else {
        validateValue(e.value, type, app.models, found, e.key);
      }
    }
    if (found.hasErrors) return const BackendResult.error('invalidFields');
    return app.queue(() async {
      final version = _next();
      await app.saveRemote(userId, fields);
      app.push(version, remote: fields, userId: userId);
      return BackendResult(version, remote: fields);
    });
  }

  /// Runs the remote action [name] for [userId] with [value] (untrusted:
  /// the action validates it). One at a time per app. Its `system` changes
  /// are saved, never sent; `shared` ones go to every client, `remote`
  /// ones to the caller's; the result carries what the caller sees.
  Future<BackendResult> call(
      String dir, String userId, String name, Object? value) async {
    final app = _app(dir);
    if (app == null) return const BackendResult.error('unknownApp');
    final program = app.program;
    if (program == null || !program.remoteActions.contains(name)) {
      return const BackendResult.error('unknownAction');
    }
    return app.queue(() async {
      final remote = await app.remoteOf(userId);
      final shared = await app.shared();
      final system = await app.system();
      final host = CollectHost();
      program.host = host;
      final code = await program
          .remote(name, {...remote, ...shared, ...system}, {'value': value});
      if (code.isNotEmpty) return BackendResult.error(code);

      final changed = <String, Map<String, dynamic>>{
        'remote': {},
        'shared': {},
        'system': {},
      };
      for (final delta in host.deltas) {
        for (final e in delta.entries) {
          changed[app.scopes[e.key]]?[e.key] = e.value;
        }
      }
      final version = _next();
      if (changed['system']!.isNotEmpty) await app.saveSystem(changed['system']!);
      if (changed['shared']!.isNotEmpty) await app.saveShared(changed['shared']!);
      if (changed['remote']!.isNotEmpty) {
        await app.saveRemote(userId, changed['remote']!);
      }
      app.push(version,
          remote: changed['remote']!.isEmpty ? null : changed['remote'],
          shared: changed['shared']!.isEmpty ? null : changed['shared'],
          userId: userId);
      return BackendResult(version,
          remote: changed['remote']!.isEmpty ? null : changed['remote'],
          shared: changed['shared']!.isEmpty ? null : changed['shared']);
    });
  }

  /// [dataPath] (`.state/shared.yaml`, `modules/food/.state/shared.yaml`)
  /// was edited by hand: its new values go to every client (feature
  /// toggles without a deploy). Our own writes change nothing.
  Future<void> dataChanged(String dataPath) async {
    for (final app in _apps.values) {
      if (dataPath == app.file('shared')) await app.reloadShared();
    }
  }

  void close() {
    for (final app in _apps.values) {
      app.close();
    }
  }
}

class _App {
  final MetacodeBackend backend;
  final String dir;

  _App(this.backend, this.dir);

  Map<String, String> scopes = {};
  Map<String, TypeRef> types = {};
  Map<String, Model> models = {};
  Map<String, dynamic> seeds = {};
  MetacodeProgram? program;
  final connections = <SyncConnection>[];

  Map<String, dynamic>? _shared;
  Map<String, dynamic>? _system;
  final _users = <String, Map<String, dynamic>>{};

  void configure(AppProject app, MetacodeProgram? program) {
    scopes = app.scopes;
    models = app.remoteModels;
    final state = models[stateModelName];
    types = state is ClassModel ? state.fields : {};
    seeds = app.state;
    this.program = program;
    // New fields get their seed; removed ones are dropped when next saved.
    _shared = null;
    _system = null;
    _users.clear();
  }

  Future<void> _queue = Future.value();

  /// Runs [task] after the ones before it (one at a time per app).
  Future<T> queue<T>(Future<T> Function() task) {
    final result = _queue.then((_) => task());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  String file(String name) =>
      [if (dir.isNotEmpty) dir, '.state', '$name.yaml'].join('/');

  Map<String, dynamic> _seedsOf(String scope) => {
        for (final e in seeds.entries)
          if (scopes[e.key] == scope) e.key: e.value,
      };

  /// The saved fields of [scope] over its seeds (fields the code no longer
  /// has are dropped).
  Map<String, dynamic> _load(String path, String scope) {
    final seed = _seedsOf(scope);
    final saved = readYamlDocument(backend.data.read(path), 'state') ?? {};
    return {
      ...seed,
      for (final e in saved.entries)
        if (seed.containsKey(e.key)) e.key: e.value,
    };
  }

  Future<Map<String, dynamic>> shared() async =>
      _shared ??= _load(file('shared'), 'shared');

  Future<Map<String, dynamic>> system() async =>
      _system ??= _load(file('system'), 'system');

  /// The user's `remote` fields: their document, or the seeds when they
  /// have none yet (users are created on their first write).
  Future<Map<String, dynamic>> remoteOf(String userId) async =>
      _users[userId] ??= _load(file('users/$userId'), 'remote');

  Future<void> saveShared(Map<String, dynamic> fields) async {
    final shared = {...await this.shared(), ...fields};
    _shared = shared;
    await backend.data.write(file('shared'), yamlDocument('state', shared));
  }

  Future<void> saveSystem(Map<String, dynamic> fields) async {
    final system = {...await this.system(), ...fields};
    _system = system;
    await backend.data.write(file('system'), yamlDocument('state', system));
  }

  Future<void> saveRemote(String userId, Map<String, dynamic> fields) async {
    final remote = {...await remoteOf(userId), ...fields};
    _users[userId] = remote;
    await backend.data
        .write(file('users/$userId'), yamlDocument('state', remote));
  }

  /// `shared.yaml` changed on disk: the fields that differ go to everyone.
  Future<void> reloadShared() => queue(() async {
        final before = await shared();
        final now = _load(file('shared'), 'shared');
        final changed = {
          for (final e in now.entries)
            if (jsonEncode(before[e.key]) != jsonEncode(e.value)) e.key: e.value,
        };
        _shared = now;
        if (changed.isNotEmpty) push(backend._next(), shared: changed);
      });

  /// Sends a delta: [shared] to everyone, [remote] to [userId]'s streams.
  void push(int version,
      {Map<String, dynamic>? remote,
      Map<String, dynamic>? shared,
      String? userId}) {
    for (final c in List.of(connections)) {
      final mine = remote != null && c.userId == userId;
      if (shared == null && !mine) continue;
      c._send('delta', {
        'version': version,
        if (mine) 'remote': remote,
        'shared': ?shared,
      });
    }
  }

  void close() {
    for (final c in connections) {
      c._out.close();
    }
    connections.clear();
  }
}

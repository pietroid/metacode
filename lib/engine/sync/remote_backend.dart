// Where an app's `remote`, `shared` and `system` state lives and where its
// remote actions run (docs/STATE_ARCHITECTURE.md, section 5). None of it is
// visible to the app: local actions emit `remote` fields and call
// `remote.<name>()`, and the engine does the rest.
//
// - [LocalBackend]: no backend (no `backend:`, the editor, the layout
//   check): remote actions run on the device against a local `system` and
//   `shared`, one user.
// - `HttpBackend` (http_backend.dart): a Metacode backend (bin/server.dart),
//   synced over SSE, offline first.

import 'dart:async';

import '../host_plugin.dart';
import '../project_config.dart';
import '../state_bloc.dart';
import '../yaml_writer.dart';

/// One app's link to its backend.
abstract class RemoteBackend {
  /// Starts syncing (connects, sends what's pending). Called once.
  void start() {}

  /// A local action emitted these `remote` fields (already in the state):
  /// send them up.
  void changed(Map<String, dynamic> fields) {}

  /// Runs the remote action [name] with [value]. Completes once its
  /// changes are in the state: with null, or the code of its refusal,
  /// `offline` or `failed`.
  Future<String?> call(String name, Object? value, {String? locale});

  /// A new version of the app (same state).
  void reconfigure(ProjectConfig config) {}

  void dispose() {}
}

/// No backend: the remote actions run on the device, one at a time, over
/// the state's `remote` and `shared` fields and a local `system`
/// (`.state/system.yaml`, seeded from app.yaml). `remote` and `shared` are
/// saved with the rest of the state ([StateBloc]).
class LocalBackend extends RemoteBackend {
  final StateBloc bloc;
  ProjectConfig _config;

  LocalBackend(this.bloc, this._config);

  Map<String, dynamic>? _system;
  Future<void> _queue = Future.value();

  @override
  void reconfigure(ProjectConfig config) => _config = config;

  Future<Map<String, dynamic>> _loadSystem() async {
    final saved = bloc.store == null
        ? null
        : readYamlDocument(
            await bloc.store!.read(bloc.app, file: 'system'), 'state');
    return {..._config.systemSeed, ...?saved};
  }

  @override
  Future<String?> call(String name, Object? value, {String? locale}) {
    final done = Completer<String?>();
    _queue = _queue.then((_) async {
      try {
        done.complete(await _run(name, value));
      } catch (e) {
        done.complete('failed');
      }
    });
    return done.future;
  }

  Future<String?> _run(String name, Object? value) async {
    final program = _config.remoteProgram;
    if (program == null) return 'unknownAction';
    final system = _system ??= await _loadSystem();
    final fields = _config.remoteFields.toSet();
    final deltas = CollectHost();
    program.host = deltas;
    final code = await program.remote(name, {
      for (final e in bloc.state.entries)
        if (fields.contains(e.key)) e.key: e.value,
      for (final f in fields)
        if (system.containsKey(f)) f: system[f],
    }, {'value': value});
    if (code.isNotEmpty) return code;

    final toState = <String, dynamic>{};
    var systemChanged = false;
    for (final delta in deltas.deltas) {
      for (final e in delta.entries) {
        if (_config.scopes.containsKey(e.key)) {
          toState[e.key] = e.value;
        } else {
          system[e.key] = e.value;
          systemChanged = true;
        }
      }
    }
    if (systemChanged && bloc.store != null) {
      await bloc.store!
          .write(bloc.app, yamlDocument('state', system), file: 'system');
    }
    if (toState.isNotEmpty) await bloc.setState({...bloc.state, ...toState});
    return null;
  }
}

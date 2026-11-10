import 'package:flutter_bloc/flutter_bloc.dart';

import 'project_config.dart';
import 'state_store.dart';
import 'yaml_writer.dart';

/// The state of one app (each module has its own), persisted as YAML by
/// scope (see [_writeState]; the backend's sync is `lib/engine/sync/`).
///
/// [initialize] loads the app's `state.yaml` from [store] (see
/// state_store.dart: next to the sources when running from the project's
/// files, the documents folder otherwise), starting from the bundled
/// initial state when there is none, and it is written back on every
/// change. Without a store the state lives in memory.
class StateBloc extends Cubit<Map<String, dynamic>> {
  ProjectConfig _config;

  /// The app version this state belongs to (see [reconfigure]).
  ProjectConfig get config => _config;

  /// Where the state is saved; null keeps it in memory.
  final StateStore? store;

  /// The app's module folders: `[]` for the root, `[food]` for
  /// `modules/food/`.
  final List<String> app;

  bool _persistent = false;

  StateBloc({
    required this._config,
    Map<String, dynamic>? initial,
    this.store,
    this.app = const [],
  }) : super(initial ?? {});

  /// Whether changes are saved (after [initialize]).
  bool get persistent => _persistent;

  /// The state of the module [name], saved next to this one when this one
  /// is.
  StateBloc child(String name, ProjectConfig config) {
    final bloc = StateBloc(
      config: config,
      initial: Map<String, dynamic>.from(config.initialState),
      store: store,
      app: [...app, name],
    );
    if (persistent) bloc.initialize();
    return bloc;
  }

  Future<void> initialize() async {
    final store = this.store;
    if (store == null) return;
    _persistent = true;
    final scopes = config.scopes;
    final saved = <String, dynamic>{};
    for (final file in const ['state', 'remote', 'shared']) {
      final fields =
          readYamlDocument(await store.read(app, file: file), 'state') ?? {};
      for (final e in fields.entries) {
        // A field saved under another scope before (it moved): dropped.
        final scope = scopes[e.key] ?? 'local';
        if (file == 'state' ? scope == 'local' : scope == file) {
          saved[e.key] = e.value;
        }
      }
    }
    final state = _overInitial(saved);
    emit(state);
    await _writeState(state);
  }

  /// Moves this state to a new version of the app (a regenerated or
  /// downloaded bundle), keeping its values; fields the new version adds
  /// get their initial value.
  void reconfigure(ProjectConfig config) {
    _config = config;
    emit(_overInitial(state));
  }

  /// [saved] over the initial state, so fields added since it was saved
  /// get their initial value.
  Map<String, dynamic> _overInitial(Object? saved) => {
        ...config.initialState,
        if (saved is Map) ...Map<String, dynamic>.from(saved),
      };

  Future<void> setState(Map<String, dynamic> newState) async {
    emit(Map<String, dynamic>.from(newState));
    await _writeState(newState);
  }

  /// Saves [data] by scope: `local` fields (and fields with no scope) in
  /// `.state/state.yaml`, `remote` and `shared` in `remote.yaml` and
  /// `shared.yaml` (the last known values, so the app opens offline with
  /// them). `ephemeral` fields are never saved. Unchanged files are not
  /// rewritten.
  Future<void> _writeState(Map<String, dynamic> data) async {
    if (!_persistent) return;
    final scopes = config.scopes;
    final byFile = <String, Map<String, dynamic>>{'state': {}};
    for (final e in data.entries) {
      final file = switch (scopes[e.key] ?? 'local') {
        'ephemeral' || 'system' => null,
        'remote' => 'remote',
        'shared' => 'shared',
        _ => 'state',
      };
      if (file != null) (byFile[file] ??= {})[e.key] = e.value;
    }
    for (final MapEntry(key: file, value: fields) in byFile.entries) {
      final yaml = yamlDocument('state', fields);
      if (_written[file] == yaml) continue;
      _written[file] = yaml;
      await store!.write(app, yaml, file: file);
    }
  }

  /// What each `.state/` file last had (see [_writeState]).
  final _written = <String, String>{};
}

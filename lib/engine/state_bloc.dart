import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaml/yaml.dart';

import 'project_config.dart';
import 'state_store.dart';

/// The state of one app (each module has its own), persisted as YAML.
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
    final saved = await store.read(app);
    if (saved != null) {
      final doc = loadYaml(saved);
      emit(_overInitial(doc is Map ? yamlToDart(doc['state']) : null));
    } else {
      final initial = Map<String, dynamic>.from(config.initialState);
      emit(initial);
      await _writeState(initial);
    }
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

  Future<void> _writeState(Map<String, dynamic> data) async {
    if (!_persistent) return;
    await store!.write(app, 'state:\n${_toYaml(data)}');
  }

  /// [value] as block YAML at [indent], nested lists and maps at any depth
  /// (a list of models whose fields are lists, like a recipe's tags).
  /// Empty lists and maps are written inline (`[]`, `{}`), never as a bare
  /// `key:`, which would read back as null.
  String _toYaml(dynamic value, {int indent = 1}) {
    final prefix = '  ' * indent;
    bool isBlock(dynamic v) =>
        (v is Map && v.isNotEmpty) || (v is List && v.isNotEmpty);
    if (value is Map) {
      return value.entries.map((e) {
        final v = e.value;
        if (isBlock(v)) {
          return '$prefix${e.key}:\n${_toYaml(v, indent: indent + 1)}';
        }
        return '$prefix${e.key}: ${_scalarYaml(v)}';
      }).join('\n');
    }
    if (value is List) {
      return value.map((item) {
        if (isBlock(item)) {
          // The item's own block one level deeper, its first line after
          // the dash: `- name: x` then `  tags:` aligned under `name`.
          final block = _toYaml(item, indent: indent + 1);
          return '$prefix- ${block.substring(prefix.length + 2)}';
        }
        return '$prefix- ${_scalarYaml(item)}';
      }).join('\n');
    }
    return '$prefix${_scalarYaml(value)}';
  }

  /// A value written on one line: an empty list or map, or a scalar.
  String _scalarYaml(dynamic value) {
    if (value is List) return '[]';
    if (value is Map) return '{}';
    return _escapeYaml(value);
  }

  /// Strings are always written as JSON strings (valid YAML), so a string
  /// that looks like a number, a bool or a date ("10", "true") reads back as
  /// a string.
  String _escapeYaml(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return value.toString();
    return jsonEncode(value.toString());
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

import 'project_config.dart';

/// The state of one app (each module has its own), persisted as YAML.
///
/// [initialize] loads `.state/state.yaml` from the app documents folder
/// (`<projectName>/.state/state.yaml`, and
/// `<projectName>/modules/<name>/.state/state.yaml` for modules), starting from
/// the bundled initial state when there is none, and the file is written back
/// on every change.
class StateBloc extends Cubit<Map<String, dynamic>> {
  final ProjectConfig config;

  /// Folders under the documents folder: `[metacode]`,
  /// `[metacode, modules, food]`.
  final List<String> path;
  File? _stateFile;

  StateBloc({
    required this.config,
    Map<String, dynamic>? initial,
    List<String>? path,
  })  : path = path ?? [config.projectName],
        super(initial ?? {});

  /// When set (via `--dart-define=METACODE_STATE_PATH=...`), the root app's
  /// state is read from and written to this file directly, e.g. the
  /// project's own `metacode/.state/state.yaml` during development.
  static const _overridePath = String.fromEnvironment('METACODE_STATE_PATH');

  /// Whether changes are written to disk (after [initialize]).
  bool get persistent => _stateFile != null;

  /// The state of the module [name], persisted next to this one when this
  /// one is.
  StateBloc child(String name, ProjectConfig config) {
    final bloc = StateBloc(
      config: config,
      initial: Map<String, dynamic>.from(config.initialState),
      path: [...path, 'modules', name],
    );
    if (persistent) bloc.initialize();
    return bloc;
  }

  Future<void> initialize() async {
    if (_overridePath.isNotEmpty && path.length == 1) {
      _stateFile = File(_overridePath);
      if (_stateFile!.existsSync()) {
        await _load();
        return;
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory([dir.path, ...path, '.state'].join('/'));
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    _stateFile = File('${folder.path}/state.yaml');

    if (_stateFile!.existsSync()) {
      await _load();
    } else {
      final initial = Map<String, dynamic>.from(config.initialState);
      emit(initial);
      await _writeState(initial);
    }
  }

  /// Saved values over the bundled initial state, so fields added since the
  /// file was written get their initial value.
  Future<void> _load() async {
    final doc = loadYaml(await _stateFile!.readAsString());
    final saved = doc is Map ? yamlToDart(doc['state']) : null;
    emit({
      ...config.initialState,
      if (saved is Map) ...Map<String, dynamic>.from(saved),
    });
  }

  Future<void> setState(Map<String, dynamic> newState) async {
    emit(Map<String, dynamic>.from(newState));
    await _writeState(newState);
  }

  Future<void> _writeState(Map<String, dynamic> data) async {
    if (_stateFile == null) return;
    final yaml = _toYaml(data);
    await _stateFile!.writeAsString('state:\n$yaml');
  }


  String _toYaml(dynamic value, {int indent = 1}) {
    final prefix = '  ' * indent;
    if (value is Map) {
      return value.entries.map((e) {
        final v = e.value;
        if (v is Map || v is List) {
          return '$prefix${e.key}:\n${_toYaml(v, indent: indent + 1)}';
        }
        return '$prefix${e.key}: ${_escapeYaml(v)}';
      }).join('\n');
    }
    if (value is List) {
      return value.map((item) {
        if (item is Map) {
          final entries = item.entries.toList();
          if (entries.isEmpty) return '$prefix- {}';
          final first = entries.first;
          final rest = entries.sublist(1);
          var out = '$prefix- ${first.key}: ${_escapeYaml(first.value)}';
          for (final e in rest) {
            out += '\n$prefix  ${e.key}: ${_escapeYaml(e.value)}';
          }
          return out;
        }
        return '$prefix- ${_escapeYaml(item)}';
      }).join('\n');
    }
    return '$prefix${_escapeYaml(value)}';
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

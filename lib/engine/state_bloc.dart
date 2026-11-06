import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

import 'project_config.dart';

/// The single source of truth for the application's YAML state.
///
/// It loads [state.yaml] from the app's documents directory on startup
/// (copying the bundled initial state if none exists yet) and writes the
/// file back on every change.
class StateBloc extends Cubit<Map<String, dynamic>> {
  final ProjectConfig config;
  File? _stateFile;

  StateBloc({required this.config, Map<String, dynamic>? initial})
      : super(initial ?? {});

  /// When set (via `--dart-define=METACODE_STATE_PATH=...`), state is read
  /// from and written to this file directly — e.g. the project's own
  /// `metacode/state.yaml` during development.
  static const _overridePath = String.fromEnvironment('METACODE_STATE_PATH');

  Future<void> initialize() async {
    if (_overridePath.isNotEmpty) {
      _stateFile = File(_overridePath);
      if (_stateFile!.existsSync()) {
        final doc = loadYaml(await _stateFile!.readAsString());
        emit(Map<String, dynamic>.from(_yamlToMap(doc['state']) ?? {}));
        return;
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/${config.projectName}');
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    _stateFile = File('${folder.path}/state.yaml');

    if (_stateFile!.existsSync()) {
      final content = await _stateFile!.readAsString();
      final doc = loadYaml(content);
      emit(Map<String, dynamic>.from(_yamlToMap(doc['state']) ?? {}));
    } else {
      final initial = Map<String, dynamic>.from(config.initialState);
      emit(initial);
      await _writeState(initial);
    }
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

  static dynamic _yamlToMap(dynamic node) {
    if (node is YamlMap) {
      return Map<String, dynamic>.fromEntries(
        node.entries.map((e) => MapEntry(e.key.toString(), _yamlToMap(e.value))),
      );
    }
    if (node is YamlList) {
      return node.map(_yamlToMap).toList();
    }
    return node;
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

  String _escapeYaml(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return value.toString();
    final str = value.toString();
    if (str.contains(':') || str.contains('#') || str.contains('"') ||
        str.contains('\n') || str.isEmpty) {
      return '"${str.replaceAll('"', '\\"')}"';
    }
    return str;
  }
}

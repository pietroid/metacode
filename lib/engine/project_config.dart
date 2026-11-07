import 'dart:convert';

import 'package:app_ui/style.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import 'navigation.dart';
import 'program.dart';

/// In-memory representation of a Metacode project.
///
/// Everything here is produced or validated by `dart run tool/metacode.dart`.
class ProjectConfig {
  final String projectName;
  final String description;
  final Map<String, dynamic> ui;
  final Map<String, dynamic> initialState;
  final MetacodeProgram program;

  /// navigation.yaml (validated by the tool), or a single `homePage`.
  final Navigation navigation;

  /// style.yaml merged over the Metacode style (see app_ui's style.dart).
  final Map<String, dynamic> style;

  ProjectConfig({
    required this.projectName,
    required this.description,
    required this.ui,
    required this.initialState,
    required this.program,
    Map<String, dynamic>? style,
    Navigation? navigation,
  })  : style = style ?? resolveStyle(null),
        navigation = navigation ?? Navigation.fallback;

  static Future<ProjectConfig> load() async {
    final project = (await _loadYaml('metacode/project.yaml'))!;
    final ui = (await _loadYaml('metacode/ui.yaml'))!;
    final stateDoc = (await _loadYaml('metacode/state.yaml'))!;
    final style = await _loadYaml('metacode/style.yaml', optional: true);
    final navigation =
        await _loadYaml('metacode/navigation.yaml', optional: true);

    final bytecode = await rootBundle.load('metacode/generated/program.evc');
    final manifest = jsonDecode(
      await rootBundle.loadString('metacode/generated/manifest.json'),
    ) as Map<String, dynamic>;

    return ProjectConfig(
      projectName: project['name'] ?? 'metacode',
      description: project['description'] ?? '',
      ui: ui,
      initialState: Map<String, dynamic>.from(stateDoc['state'] ?? {}),
      program: MetacodeProgram(bytecode, manifest),
      style: resolveStyle(style),
      navigation: navigation == null ? null : Navigation.parse(navigation),
    );
  }

  static Future<Map<String, dynamic>?> _loadYaml(String asset,
      {bool optional = false}) async {
    final String text;
    try {
      text = await rootBundle.loadString(asset);
    } catch (_) {
      if (optional) return null;
      rethrow;
    }
    return yamlToDart(loadYaml(text));
  }
}

/// Converts parsed YAML nodes into plain Dart maps and lists.
dynamic yamlToDart(dynamic node) {
  if (node is YamlMap) {
    return Map<String, dynamic>.fromEntries(
      node.entries.map((e) => MapEntry(e.key.toString(), yamlToDart(e.value))),
    );
  }
  if (node is YamlList) {
    return node.map(yamlToDart).toList();
  }
  return node;
}

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

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

  ProjectConfig({
    required this.projectName,
    required this.description,
    required this.ui,
    required this.initialState,
    required this.program,
  });

  static Future<ProjectConfig> load() async {
    final project = await _loadYaml('metacode/project.yaml');
    final ui = await _loadYaml('metacode/ui.yaml');
    final stateDoc = await _loadYaml('metacode/state.yaml');

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
    );
  }

  static Future<Map<String, dynamic>> _loadYaml(String asset) async {
    return yamlToDart(loadYaml(await rootBundle.loadString(asset)));
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

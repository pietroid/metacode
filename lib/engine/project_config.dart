import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// In-memory representation of the Metacode project files.
class ProjectConfig {
  final String projectName;
  final String description;
  final Map<String, dynamic> models;
  final Map<String, dynamic> ui;
  final Map<String, dynamic> initialState;
  final String bindingsSource;
  final String actionsSource;

  ProjectConfig({
    required this.projectName,
    required this.description,
    required this.models,
    required this.ui,
    required this.initialState,
    required this.bindingsSource,
    required this.actionsSource,
  });

  static Future<ProjectConfig> load() async {
    final projectYaml = await rootBundle.loadString('metacode/project.yaml');
    final project = _yamlToMap(loadYaml(projectYaml));

    final modelsYaml = await rootBundle.loadString('metacode/models.yaml');
    final models = _yamlToMap(loadYaml(modelsYaml));

    final uiYaml = await rootBundle.loadString('metacode/ui.yaml');
    final ui = _yamlToMap(loadYaml(uiYaml));

    final stateYaml = await rootBundle.loadString('metacode/state.yaml');
    final stateDoc = _yamlToMap(loadYaml(stateYaml));
    final initialState = Map<String, dynamic>.from(stateDoc['state'] ?? {});

    final bindingsSource = await rootBundle.loadString('bindings/lib/bindings.dart');
    final actionsSource = await rootBundle.loadString('actions/lib/actions.dart');

    return ProjectConfig(
      projectName: project['name'] ?? 'new_metacode',
      description: project['description'] ?? '',
      models: models,
      ui: ui,
      initialState: initialState,
      bindingsSource: bindingsSource,
      actionsSource: actionsSource,
    );
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
}

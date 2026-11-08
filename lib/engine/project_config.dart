import 'dart:convert';
import 'dart:typed_data';

import 'package:app_ui/style.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import 'navigation.dart';
import 'program.dart';

/// In-memory representation of a Metacode app and, recursively, its
/// modules (`modules/<name>/`).
///
/// Everything here is produced or validated by `dart run tool/metacode.dart`,
/// which writes the whole tree to `examples/my_own_app/.generated/bundle.json`.
class ProjectConfig {
  final String projectName;
  final String description;
  final Map<String, dynamic> ui;
  final Map<String, dynamic> initialState;
  final MetacodeProgram program;

  /// app/views/labels/ in the current language: key -> text.
  final Map<String, String> labels;

  /// app/views/navigation.yaml (validated by the tool), or a single `MainPage`.
  final Navigation navigation;

  /// style/ merged over the Metacode style (see app_ui's style.dart).
  final Map<String, dynamic> style;

  /// Whether the app has its own style/. Modules without one inherit the
  /// theme of the app that embeds them.
  final bool hasOwnStyle;

  /// Modules by folder name, embedded with the `module:` widget.
  final Map<String, ProjectConfig> modules;

  ProjectConfig({
    required this.projectName,
    required this.description,
    required this.ui,
    required this.initialState,
    required this.program,
    this.labels = const {},
    Map<String, dynamic>? style,
    Navigation? navigation,
    this.modules = const {},
  })  : style = style ?? resolveStyle(null),
        hasOwnStyle = style != null,
        navigation = navigation ?? Navigation.fallback;

  /// The engine's only project asset.
  static const bundleAsset = 'examples/my_own_app/.generated/bundle.json';

  static Future<ProjectConfig> load() async =>
      ProjectConfig.fromBundle(jsonDecode(await loadBundle()) as Map);

  /// The raw bundle, read fresh (not cached), so a regenerated one is seen
  /// after a hot reload.
  static Future<String> loadBundle() =>
      rootBundle.loadString(bundleAsset, cache: false);

  /// Builds the app tree from `generated/bundle.json`.
  factory ProjectConfig.fromBundle(Map json) {
    final manifest = Map<String, dynamic>.from(json['manifest'] as Map);
    final bytecode = base64Decode(json['program'] as String);
    final style = json['style'];
    final navigation = json['navigation'];
    return ProjectConfig(
      projectName: json['name'] as String? ?? 'metacode',
      description: json['description'] as String? ?? '',
      ui: Map<String, dynamic>.from(json['ui'] as Map),
      initialState: Map<String, dynamic>.from(json['state'] as Map? ?? {}),
      program: MetacodeProgram(ByteData.sublistView(bytecode), manifest),
      labels: _labels(json['labels'], json['language']),
      style: style == null ? null : resolveStyle(style),
      navigation: navigation == null ? null : Navigation.parse(navigation),
      modules: {
        for (final e in ((json['modules'] as Map?) ?? {}).entries)
          e.key.toString(): ProjectConfig.fromBundle(e.value as Map),
      },
    );
  }
}

/// The labels of [language] (the default one), over nothing else yet.
Map<String, String> _labels(dynamic labels, dynamic language) {
  if (labels is! Map || labels[language] is! Map) return const {};
  return {
    for (final e in (labels[language] as Map).entries)
      e.key.toString(): e.value.toString(),
  };
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

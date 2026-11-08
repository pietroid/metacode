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

  /// app.yaml `start:`: the action run when the app starts, if any.
  final String? start;

  /// app/views/labels/: language (the file name, `en`, `pt_br`) -> key ->
  /// text.
  final Map<String, Map<String, String>> labels;

  /// The language of keys other languages lack (`en` when there is one).
  final String? defaultLanguage;

  /// app/views/navigation.yaml (validated by the tool), or a single `MainPage`.
  final Navigation navigation;

  /// style/ merged over the Metacode style (see app_ui's style.dart).
  final Map<String, dynamic> style;

  /// Whether the app has its own style/. Modules without one inherit the
  /// theme of the app that embeds them.
  final bool hasOwnStyle;

  /// Modules by folder name, embedded with the `module:` widget.
  final Map<String, ProjectConfig> modules;

  /// App files (images) by repo-relative path, when the app runs from the
  /// project's files (lib/engine/live_project.dart); null for bundled
  /// assets.
  final Uint8List? Function(String path)? readFile;

  ProjectConfig({
    required this.projectName,
    required this.description,
    required this.ui,
    required this.initialState,
    required this.program,
    this.start,
    this.labels = const {},
    this.defaultLanguage,
    Map<String, dynamic>? style,
    Navigation? navigation,
    this.modules = const {},
    this.readFile,
  })  : style = style ?? resolveStyle(null),
        hasOwnStyle = style != null,
        navigation = navigation ?? Navigation.fallback;

  /// The engine's only project asset.
  static const bundleAsset = 'examples/my_own_app/.generated/bundle.json';

  static Future<ProjectConfig> load() async =>
      ProjectConfig.fromBundle(jsonDecode(await loadBundle()) as Map);

  /// The raw bundle, read fresh (not cached), so a regenerated one is seen
  /// after a hot reload (when the app runs without live files).
  static Future<String> loadBundle() =>
      rootBundle.loadString(bundleAsset, cache: false);

  /// Builds the app tree from `generated/bundle.json`. [readFile] (shared by
  /// every module) serves app files from the project's files.
  factory ProjectConfig.fromBundle(Map json,
      {Uint8List? Function(String path)? readFile}) {
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
      start: json['start'] as String?,
      labels: _labels(json['labels']),
      defaultLanguage: json['language'] as String?,
      style: style == null ? null : resolveStyle(style),
      navigation: navigation == null ? null : Navigation.parse(navigation),
      modules: {
        for (final e in ((json['modules'] as Map?) ?? {}).entries)
          e.key.toString():
              ProjectConfig.fromBundle(e.value as Map, readFile: readFile),
      },
      readFile: readFile,
    );
  }
}

Map<String, Map<String, String>> _labels(dynamic labels) {
  if (labels is! Map) return const {};
  return {
    for (final MapEntry(:key, :value) in labels.entries)
      if (value is Map)
        key.toString(): {
          for (final e in value.entries) e.key.toString(): e.value.toString(),
        },
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

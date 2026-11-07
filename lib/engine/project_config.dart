import 'dart:convert';
import 'dart:typed_data';

import 'package:app_ui/style.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import 'navigation.dart';
import 'program.dart';

/// In-memory representation of a Metacode app and, recursively, its
/// sub-apps (`apps/<name>/`).
///
/// Everything here is produced or validated by `dart run tool/metacode.dart`,
/// which writes the whole tree to `metacode/generated/bundle.json`.
class ProjectConfig {
  final String projectName;
  final String description;
  final Map<String, dynamic> ui;
  final Map<String, dynamic> initialState;
  final MetacodeProgram program;

  /// navigation/ (validated by the tool), or a single `homePage`.
  final Navigation navigation;

  /// style/ merged over the Metacode style (see app_ui's style.dart).
  final Map<String, dynamic> style;

  /// Whether the app has its own style/. Sub-apps without one inherit the
  /// theme of the app that embeds them.
  final bool hasOwnStyle;

  /// Sub-apps by folder name, embedded with the `app:` widget.
  final Map<String, ProjectConfig> apps;

  ProjectConfig({
    required this.projectName,
    required this.description,
    required this.ui,
    required this.initialState,
    required this.program,
    Map<String, dynamic>? style,
    Navigation? navigation,
    this.apps = const {},
  })  : style = style ?? resolveStyle(null),
        hasOwnStyle = style != null,
        navigation = navigation ?? Navigation.fallback;

  /// The engine's only project asset.
  static const bundleAsset = 'metacode/generated/bundle.json';

  static Future<ProjectConfig> load() async => ProjectConfig.fromBundle(
      jsonDecode(await rootBundle.loadString(bundleAsset)) as Map);

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
      style: style == null ? null : resolveStyle(style),
      navigation: navigation == null ? null : Navigation.parse(navigation),
      apps: {
        for (final e in ((json['apps'] as Map?) ?? {}).entries)
          e.key.toString(): ProjectConfig.fromBundle(e.value as Map),
      },
    );
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

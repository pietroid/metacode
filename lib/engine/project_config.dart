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
  /// The client's initial state: every field but `system`'s.
  final Map<String, dynamic> initialState;
  final MetacodeProgram program;

  /// Each client field's scope: `ephemeral`, `local`, `remote`, `shared`
  /// (docs/STATE_ARCHITECTURE.md). Empty for an app whose state isn't
  /// split: every field is then `local`.
  final Map<String, String> scopes;

  /// The remote actions' program (app/actions/remote/), run on the device
  /// when there is no backend; null when the app has none.
  final MetacodeProgram? remoteProgram;

  /// The `system` fields' seeds (app.yaml), for running without a backend.
  final Map<String, dynamic> systemSeed;

  /// The fields remote actions see: `remote`, `shared` and `system`.
  final List<String> remoteFields;

  /// The backend's URL (root app.yaml `backend:`), if any.
  final String? backend;

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

  /// Whether the app has state on the backend (`remote` or `shared` fields)
  /// or remote actions, so it syncs.
  bool get syncs =>
      remoteProgram != null ||
      scopes.values.any((s) => s == 'remote' || s == 'shared');

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
    this.scopes = const {},
    this.remoteProgram,
    this.systemSeed = const {},
    this.remoteFields = const [],
    this.backend,
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
    final remote = json['remote'] as Map?;
    return ProjectConfig(
      projectName: json['name'] as String? ?? 'metacode',
      description: json['description'] as String? ?? '',
      ui: Map<String, dynamic>.from(json['ui'] as Map),
      initialState: Map<String, dynamic>.from(json['state'] as Map? ?? {}),
      program: MetacodeProgram(ByteData.sublistView(bytecode), manifest),
      scopes: {
        for (final e in ((json['scopes'] as Map?) ?? const {}).entries)
          e.key.toString(): e.value.toString(),
      },
      remoteProgram: remote == null
          ? null
          : MetacodeProgram(
              ByteData.sublistView(base64Decode(remote['program'] as String)),
              {'remote': manifest['remote']}),
      systemSeed: Map<String, dynamic>.from((remote?['system'] as Map?) ?? {}),
      remoteFields: [
        for (final f in (remote?['fields'] as List?) ?? const []) f.toString(),
      ],
      backend: json['backend'] as String?,
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

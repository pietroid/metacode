import 'dart:io';

import 'package:app_ui/style.dart';
import 'package:metacode/engine/navigation.dart';
import 'package:yaml/yaml.dart';

import 'functions.dart';
import 'issues.dart';
import 'models.dart';
import 'ui.dart';

/// One app folder, validated. An app is recursive: its sub-apps live in
/// `apps/<name>/` and have the same layout.
///
/// ```
/// app.yaml            name, description
/// models/*.yaml       models and enums (the reserved `state` model)
/// state/*.yaml        `state:` initial values
/// ui/*.yaml           `widgets:` (one namespace across files)
/// navigation/*.yaml   routes (optional)
/// style/*.yaml        design tokens (optional; sub-apps inherit the theme)
/// actions/*.dart
/// relations/*.dart
/// test/
/// apps/<name>/        sub-apps
/// generated/          output, never edited
/// ```
///
/// Every `.yaml` in a folder is read and merged (top-level keys must not
/// repeat across files), so a big ui/ can be split into several files.
class AppProject {
  final Directory dir;

  /// Folder relative to the repo root: `metacode`, `metacode/apps/food`.
  final String path;

  /// Folder name: the key `app:` widgets use (the root's is `metacode`).
  final String name;

  /// Prefix for issues, relative to `metacode/`: `''`, `apps/food/`.
  final String prefix;

  String title = '';
  String description = '';
  Map<String, Model> models = {};
  Map<String, dynamic> state = {};
  Map<String, dynamic> widgets = {};
  Navigation navigation = Navigation.fallback;
  Map<String, dynamic>? navigationDoc;
  Map<String, dynamic>? styleDoc;
  List<UserFunction> actions = [];
  List<UserFunction> bindings = [];
  final Map<String, AppProject> apps = {};

  AppProject(this.dir, this.path, this.name, this.prefix);

  /// `metacode` or `apps/food`.
  String get label =>
      prefix.isEmpty ? name : prefix.substring(0, prefix.length - 1);

  /// This app and every sub-app, depth first.
  Iterable<AppProject> get tree sync* {
    yield this;
    for (final child in apps.values) {
      yield* child.tree;
    }
  }
}

/// Folders that used to be single files at the app root.
const _legacyFiles = {
  'project.yaml': 'app.yaml',
  'models.yaml': 'models/models.yaml',
  'state.yaml': 'state/state.yaml',
  'ui.yaml': 'ui/ui.yaml',
  'navigation.yaml': 'navigation/navigation.yaml',
  'style.yaml': 'style/style.yaml',
};

/// Reads and validates the app in [dir] and, recursively, its sub-apps.
AppProject loadApp(Directory dir, String path, Issues root,
    {String name = 'metacode', String prefix = ''}) {
  final app = AppProject(dir, path, name, prefix);
  final issues = root.scoped(prefix);

  for (final legacy in _legacyFiles.entries) {
    if (File('${dir.path}/${legacy.key}').existsSync()) {
      issues.error(legacy.key, '', 'move it to ${legacy.value}');
    }
  }
  if (Directory('${dir.path}/bindings').existsSync()) {
    issues.error('bindings/', '', 'rename the folder to relations/');
  }

  // Sub-apps first: ui/ checks `app:` names against them.
  final appsDir = Directory('${dir.path}/apps');
  if (appsDir.existsSync()) {
    final children = appsDir.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final child in children) {
      final childName = child.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (!isValidName(childName)) {
        issues.error('apps/$childName/', '',
            'sub-app folders are lowerCamelCase identifiers');
        continue;
      }
      app.apps[childName] = loadApp(child, '$path/apps/$childName', root,
          name: childName, prefix: '${prefix}apps/$childName/');
    }
  }

  final appYaml = _readYaml(File('${dir.path}/app.yaml'), 'app.yaml', issues);
  if (appYaml is Map) {
    app.title = appYaml['name']?.toString() ?? name;
    app.description = appYaml['description']?.toString() ?? '';
  } else {
    if (!File('${dir.path}/app.yaml').existsSync()) {
      issues.error('app.yaml', '', 'file not found');
    } else if (appYaml != null) {
      issues.error('app.yaml', '', 'must be a map with name and description');
    }
    app.title = name;
  }

  final reader = _FolderReader(dir, issues);

  app.models = parseModels(reader.merged('models'), issues);
  app.state = reader.merged('state', under: 'state');
  validateState({'state': app.state}, app.models, issues);

  app.actions = readFunctions(
      Directory('${dir.path}/actions'), 'actions', app.models, issues);
  app.bindings = readFunctions(
      Directory('${dir.path}/relations'), 'relations', app.models, issues);

  final seen = <String, String>{};
  for (final fn in [...app.actions, ...app.bindings]) {
    final other = seen[fn.name];
    if (other != null) {
      issues.error(fn.file, fn.name, 'also defined in $other; names must be unique');
    }
    seen[fn.name] = fn.file;
  }

  final navigationFiles = reader.files('navigation', required: false);
  app.widgets = validateUi(
    reader.files('ui'),
    app.bindings.map((f) => f.name).toSet(),
    app.actions.map((f) => f.name).toSet(),
    app.apps.keys.toSet(),
    issues,
    requireHomePage: navigationFiles.isEmpty,
  );

  if (navigationFiles.isNotEmpty) {
    final doc = _mergeNavigation(navigationFiles, issues);
    final parsed = Navigation.parse(
        doc, (path, message) => issues.error('navigation/', path, message));
    for (final route in parsed?.routes.values ?? const <RouteSpec>[]) {
      if (!app.widgets.containsKey(route.widget)) {
        issues.error('navigation/', 'routes.${route.name}',
            '"${route.widget}" is not a widget in ui/');
      }
    }
    if (parsed != null) {
      app.navigation = parsed;
      app.navigationDoc = doc;
    }
  }

  final styleFiles = reader.files('style', required: false);
  if (styleFiles.isNotEmpty) {
    final style = reader.merged('style', required: false);
    for (final (path, message) in validateStyle(style)) {
      issues.error('style/', path, message);
    }
    app.styleDoc = style;
  }

  return app;
}

Map<String, dynamic> _mergeNavigation(
    Map<String, dynamic> files, Issues issues) {
  String? initial;
  String? initialFile;
  final routes = <String, dynamic>{};
  final routeFile = <String, String>{};
  for (final entry in files.entries) {
    final doc = entry.value;
    if (doc is! Map) {
      issues.error(entry.key, '', 'must be a map with "initial" and "routes"');
      continue;
    }
    if (doc['initial'] != null) {
      if (initialFile != null) {
        issues.error(entry.key, 'initial', 'also set in $initialFile');
      }
      initial = doc['initial'].toString();
      initialFile = entry.key;
    }
    final r = doc['routes'];
    if (r is Map) {
      for (final route in r.entries) {
        final key = route.key.toString();
        if (routeFile.containsKey(key)) {
          issues.error(entry.key, 'routes.$key', 'also defined in ${routeFile[key]}');
          continue;
        }
        routeFile[key] = entry.key;
        routes[key] = route.value;
      }
    }
  }
  return {'initial': initial, 'routes': routes};
}

/// Reads the `.yaml` files of an app's folders.
class _FolderReader {
  final Directory dir;
  final Issues issues;

  _FolderReader(this.dir, this.issues);

  /// Every `.yaml` in [folder], by file (`ui/home.yaml`), as plain Dart.
  Map<String, dynamic> files(String folder, {bool required = true}) {
    final d = Directory('${dir.path}/$folder');
    final found = d.existsSync()
        ? (d
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.yaml'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
        : <File>[];
    if (found.isEmpty) {
      if (required) {
        issues.error('$folder/', '', 'missing (put $folder/$folder.yaml in it)');
      }
      return {};
    }
    return {
      for (final f in found)
        '$folder/${f.uri.pathSegments.last}':
            _readYaml(f, '$folder/${f.uri.pathSegments.last}', issues),
    };
  }

  /// The files of [folder] merged into one map. With [under], each file
  /// holds its map under that key (`state:`).
  Map<String, dynamic> merged(String folder,
      {String? under, bool required = true}) {
    final out = <String, dynamic>{};
    final fileOf = <String, String>{};
    for (final entry in files(folder, required: required).entries) {
      var doc = entry.value;
      if (doc == null) continue; // empty or unreadable (already reported)
      if (under != null) {
        if (doc is! Map || doc[under] is! Map) {
          issues.error(entry.key, '', 'must contain a top-level "$under:" map');
          continue;
        }
        doc = doc[under];
      }
      if (doc is! Map) {
        issues.error(entry.key, '', 'must be a map');
        continue;
      }
      for (final e in doc.entries) {
        final key = e.key.toString();
        if (fileOf.containsKey(key)) {
          issues.error(entry.key, key, 'also defined in ${fileOf[key]}');
          continue;
        }
        fileOf[key] = entry.key;
        out[key] = e.value;
      }
    }
    return out;
  }
}

dynamic _readYaml(File file, String label, Issues issues) {
  if (!file.existsSync()) return null;
  try {
    return _plain(loadYaml(file.readAsStringSync()));
  } on YamlException catch (e) {
    issues.error(label, '', e.message);
    return null;
  }
}

/// YAML nodes -> plain maps (String keys) and lists, ready for JSON.
dynamic _plain(dynamic node) {
  if (node is Map) {
    return <String, dynamic>{
      for (final e in node.entries) e.key.toString(): _plain(e.value),
    };
  }
  if (node is List) return [for (final v in node) _plain(v)];
  return node;
}

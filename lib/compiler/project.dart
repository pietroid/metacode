// Loads one app folder (and, recursively, its modules) into an [AppProject]:
// reads every file, validates it, and keeps what codegen and the index need.

import 'package:app_ui/spec.dart' show contextParams;
import 'package:app_ui/style.dart';
import 'package:metacode/engine/navigation.dart';
import 'package:metacode/files/project_files.dart';
import 'package:yaml/yaml.dart';

import 'functions.dart';
import 'issues.dart';
import 'models.dart';
import 'ui.dart';

/// One app folder, validated. An app is recursive: its modules live in
/// `modules/<name>/` and have the same layout.
///
/// ```
/// app.yaml                  name, description, version, state (initial values),
///                           start (an action run when the app starts)
/// app/
///   actions/*.dart          one action per file; its tests in a main() below it
///   actions/shared/*.dart   helpers any code can call, one function per file
///   models/*.yaml           one model or enum per file (state.yaml: the state)
///   models/sample.dart      test fixtures: `app` (TestApp) and sample(...)
///   views/
///     navigation.yaml       routes (optional; without it the app is MainPage)
///     pages/*.yaml          what routes open: MainPage, sheets, dialogs
///     components/*.yaml     one widget per file
///     style/*.yaml          design tokens (optional; modules inherit the theme)
///     style/images/         image assets
///     values/*.dart         one value (computed from state) per file + tests
///     values/shared/*.dart  helpers any code can call, one function per file
///     labels/<language>.yaml  the app's text, pure strings (en.yaml)
/// tests/*.yaml              selected states the layout check renders (+ route)
/// modules/<name>/           modules (same layout)
/// .generated/               output, never edited (INDEX.md: the app's map)
/// .state/                   runtime state, never committed
/// ```
///
/// Every `.yaml` file contains exactly one top-level key (its parent), named
/// after the file: `example_slide.yaml` holds `ExampleSlide:`, `state.yaml`
/// holds `state:`. Files are `this_case`, keys and functions `thisCase`,
/// pages and components `ThisCase`. Files are not merged; names must not
/// repeat across files.
class AppProject {
  /// The whole project's files (the root app's folder).
  final ProjectFiles files;

  /// This app's folder within [files]: `''` for the root, `modules/food`.
  final String dir;

  /// Folder relative to the repo root: `examples/my_own_app`, `examples/my_own_app/modules/food`.
  final String path;

  /// Folder name: the key `module:` widgets use (the root's is `metacode`).
  final String name;

  /// Prefix for issues, relative to `examples/my_own_app/`: `''`, `modules/food/`.
  final String prefix;

  String title = '';
  String description = '';

  /// app.yaml `start:`: the action run when the app starts (a module: when
  /// first shown, and when `core.modules.reset` starts it over).
  String? start;
  Map<String, Model> models = {};
  Map<String, dynamic> state = {};
  Map<String, dynamic> widgets = {};

  /// Widget id -> its file (`app/views/components/hero.yaml`).
  Map<String, String> widgetFiles = {};

  /// Widget id -> what it references (for the index).
  Map<String, WidgetRefs> widgetRefs = {};

  /// File (relative to the app) -> its header comment, for every model,
  /// page, component and the app.yaml (actions and values keep theirs in
  /// [UserFunction.doc]).
  Map<String, String> docs = {};
  Navigation navigation = Navigation.fallback;
  Map<String, dynamic>? navigationDoc;
  Map<String, dynamic>? styleDoc;
  List<UserFunction> actions = [];

  /// Values (`app/views/values/`); the engine and spec still call them bindings.
  List<UserFunction> bindings = [];

  /// Helpers in app/actions/shared/ and app/views/values/shared/.
  List<UserFunction> shared = [];

  /// `tests/<name>.yaml`: a selected state (fields over the initial state)
  /// and optionally a route, which the layout check renders at every size:
  /// name -> {state: {...}, route: name?}.
  Map<String, Map<String, dynamic>> testStates = {};

  /// `app/views/labels/`: language -> key -> text. The first language is
  /// [defaultLanguage].
  Map<String, Map<String, String>> labels = {};
  String? defaultLanguage;
  final Map<String, AppProject> modules = {};

  AppProject(this.files, this.dir, this.path, this.name, this.prefix);

  /// [file] (relative to this app) within [files].
  String at(String file) => dir.isEmpty ? file : '$dir/$file';

  /// The label keys every widget and value can use.
  Map<String, String> get defaultLabels => labels[defaultLanguage] ?? const {};

  /// `metacode` or `modules/food`.
  String get label =>
      prefix.isEmpty ? name : prefix.substring(0, prefix.length - 1);

  /// This app and every module, depth first.
  Iterable<AppProject> get tree sync* {
    yield this;
    for (final child in modules.values) {
      yield* child.tree;
    }
  }
}

/// Reads and validates the app in [dir] and, recursively, its modules.
///
/// [files] holds the root app's folder; [dir] is this app's folder in it
/// (`''`, `modules/food`) and [path] the same folder relative to the repo
/// (`examples/my_own_app`), for generated code and messages.
AppProject loadApp(ProjectFiles files, String path, Issues root,
    {String dir = '', String name = 'metacode', String prefix = ''}) {
  final app = AppProject(files, dir, path, name, prefix);
  final issues = root.scoped(prefix);

  // Modules first: app/views/ checks `module:` names against them.
  {
    for (final childName in files.directories(app.at('modules'))) {
      if (!isValidName(childName)) {
        issues.error('modules/$childName/', '',
            'module folder name must be a valid identifier');
        continue;
      }
      app.modules[childName] = loadApp(
          files, '$path/modules/$childName', root,
          dir: app.at('modules/$childName'),
          name: childName,
          prefix: '${prefix}modules/$childName/');
    }
  }

  final appYaml = _readYaml(files, app.at('app.yaml'), 'app.yaml', issues);
  if (appYaml is Map) {
    app.title = appYaml['name']?.toString() ?? name;
    app.description = appYaml['description']?.toString() ?? '';
    final start = appYaml['start'];
    if (start != null) app.start = start.toString();
    final state = appYaml['state'];
    if (state is Map) {
      app.state = Map<String, dynamic>.from(state);
    }
  } else {
    if (!files.exists(app.at('app.yaml'))) {
      issues.error('app.yaml', '', 'file not found');
    } else if (appYaml != null) {
      issues.error('app.yaml', '', 'must be a map with name, description and state');
    }
    app.title = name;
  }

  final reader = _FolderReader(app, issues);

  // Models and enums; each file declares exactly one. The reserved `state`
  // model lives in models/state.yaml.
  final models = _readSingleParents(reader, 'app/models', issues, camelCase);
  app.models = parseModels(models, issues, file: 'app/models/');

  validateState({'state': app.state}, app.models, issues);

  app.actions = readFunctions(app.files, app.dir, 'app/actions', 'actions', app.models, issues);
  app.bindings =
      readFunctions(app.files, app.dir, 'app/views/values', 'values', app.models, issues);
  app.shared = [
    for (final folder in ['app/actions', 'app/views/values'])
      ...readShared(app.files, app.dir, folder, issues),
  ];

  final start = app.start;
  if (start != null) {
    final action = app.actions.where((a) => a.name == start).firstOrNull;
    if (action == null) {
      issues.error('app.yaml', 'start', '"$start" is not an action; '
          'available: ${app.actions.map((a) => a.name).join(', ')}');
    } else if (action.params.any((p) => contextParams.contains(p.name))) {
      issues.error('app.yaml', 'start', '"$start" takes '
          '${action.params.where((p) => contextParams.contains(p.name)).map((p) => p.name).join(', ')}; '
          'a start action has no index or value');
    }
  }

  final seen = <String, String>{};
  for (final fn in [...app.actions, ...app.bindings, ...app.shared]) {
    final other = seen[fn.name];
    if (other != null) {
      issues.error(fn.file, fn.name, 'also defined in $other; names must be unique');
    }
    seen[fn.name] = fn.file;
    if (baseName(fn.file) != snakeCase(fn.name)) {
      issues.error(fn.file, fn.name,
          'the file must be named after its function: ${snakeCase(fn.name)}.dart');
    }
  }

  _readLabels(app, reader, issues);
  for (final key in app.defaultLabels.keys) {
    final other = seen[key];
    if (other != null) {
      issues.error('app/views/labels/', key,
          'is also the name of a function in $other; names must be unique');
    }
  }

  final navigationDoc = reader.single('app/views/navigation.yaml');
  final pages = _readWidgets(reader, 'app/views/pages', issues);
  final components = _readWidgets(reader, 'app/views/components', issues);
  for (final id in components.widgets.keys) {
    final other = pages.fileOf[id];
    if (other != null) {
      issues.error(components.fileOf[id]!, id, 'also defined in $other');
    }
  }
  app.widgetFiles = {...components.fileOf, ...pages.fileOf};
  app.widgets = validateWidgets(
    {...components.widgets, ...pages.widgets},
    app.widgetFiles,
    app.bindings.map((f) => f.name).toSet(),
    app.defaultLabels.keys.toSet(),
    app.actions.map((f) => f.name).toSet(),
    app.modules.keys.toSet(),
    issues,
    requireMainPage: navigationDoc == null,
    refs: app.widgetRefs,
  );
  for (final file in {
    'app.yaml',
    ...app.widgetFiles.values,
    for (final f in files.list(app.at('app/models')))
      if (f.endsWith('.yaml')) app.dir.isEmpty ? f : f.substring(app.dir.length + 1),
  }) {
    final source = files.read(app.at(file));
    if (source == null) continue;
    // The header starts with the file's key (`Hero:`, `state:`); app.yaml's
    // with the app's folder name.
    final key = file == 'app.yaml'
        ? name
        : RegExp(r'^([A-Za-z]\w*):', multiLine: true)
                .firstMatch(source)
                ?.group(1) ??
            '';
    app.docs[file] = headerComment(source, key);
  }

  if (navigationDoc != null) {
    const file = 'app/views/navigation.yaml';
    final doc = navigationDoc is Map
        ? Map<String, dynamic>.from(navigationDoc)
        : <String, dynamic>{};
    if (navigationDoc is! Map) {
      issues.error(file, '', 'must be a map with "initial" and "routes"');
    }
    final parsed =
        Navigation.parse(doc, (path, message) => issues.error(file, path, message));
    for (final route in parsed?.routes.values ?? const <RouteSpec>[]) {
      if (!pages.widgets.containsKey(route.widget)) {
        issues.error(file, 'routes.${route.name}',
            '"${route.widget}" is not a page in app/views/pages/');
      }
    }
    if (parsed != null) {
      app.navigation = parsed;
      app.navigationDoc = doc;
    }
  }

  _readTestStates(app, reader, issues);

  final styleFiles = reader.files('app/views/style', required: false);
  if (styleFiles.isNotEmpty) {
    final style = reader.merged('app/views/style', required: false, recursive: true);
    for (final (path, message) in validateStyle(style)) {
      issues.error('app/views/style/', path, message);
    }
    app.styleDoc = style;
  }

  return app;
}

/// Reads `tests/<name>.yaml`: `name: {state: {stage: plan, ...}, route: x}`.
/// Only selected states worth a look (a screen the initial state never
/// shows), not every combination. Each is checked against the state model,
/// over the initial state, and its route against navigation.
void _readTestStates(AppProject app, _FolderReader reader, Issues issues) {
  final docs = _readSingleParents(reader, 'tests', issues, camelCase);
  for (final MapEntry(key: name, value: doc) in docs.entries) {
    final file = 'tests/${snakeCase(name)}.yaml';
    if (doc is! Map || doc['state'] is! Map ||
        doc.keys.any((k) => k != 'state' && k != 'route')) {
      issues.error(file, name, 'must be a map with "state:" (the fields that '
          'differ from the initial state) and optionally "route:"');
      continue;
    }
    final state = Map<String, dynamic>.from(doc['state'] as Map);
    // Over the initial state, so the fields it leaves out count as set;
    // only problems with its own fields are reported (app.yaml's are
    // reported there).
    final found = Issues();
    validateState({'state': {...app.state, ...state}}, app.models, found,
        file: file);
    for (final e in found.errors) {
      if (state.keys.any((k) =>
          RegExp('> state\\.$k(\$|[.\\[:])').hasMatch(e) ||
          e.contains('"$k" is not a field'))) {
        issues.errors.add(issues.prefix + e);
      }
    }
    final route = doc['route'];
    if (route != null && !app.navigation.routes.containsKey(route)) {
      issues.error(file, '$name.route', '"$route" is not a route in '
          'app/views/navigation.yaml');
    }
    app.testStates[name] = {'state': state, 'route': ?route};
    app.docs[file] = headerComment(app.files.read(app.at(file)) ?? '', name);
  }
}

/// A labels file name: a language (`en`, `pt`), optionally with a region
/// (`pt_br`, `en_us`). The engine maps it to a Flutter `Locale`.
final languageFileName = RegExp(r'^[a-z]{2,3}(_[a-z]{2}|_[0-9]{3})?$');

/// Reads `app/views/labels/<language>.yaml`: `en: {joinTitle: Join the waitlist}`.
/// Labels are pure strings; values join them with state (they take
/// `Labels labels`). Every language must have the default one's keys.
void _readLabels(AppProject app, _FolderReader reader, Issues issues) {
  final files = reader.files('app/views/labels', required: false);
  for (final entry in files.entries) {
    final language = baseName(entry.key);
    final doc = entry.value;
    if (!languageFileName.hasMatch(language)) {
      issues.error(entry.key, '', 'name a labels file after its language: '
          'en.yaml, pt.yaml, or with a region, pt_br.yaml');
      continue;
    }
    if (doc is! Map || doc.length != 1 || doc[language] is! Map) {
      issues.error(entry.key, '', 'must contain one key, "$language:", '
          'with the labels as key: text');
      continue;
    }
    final labels = <String, String>{};
    for (final e in (doc[language] as Map).entries) {
      final key = e.key.toString();
      if (!camelCase.hasMatch(key) || dartKeywords.contains(key)) {
        issues.error(entry.key, '$language.$key', 'label keys are thisCase');
      } else if (e.value is! String) {
        issues.error(entry.key, '$language.$key',
            'labels are pure strings; build text from state in app/views/values/');
      } else {
        labels[key] = e.value as String;
      }
    }
    app.labels[language] = labels;
  }
  if (app.labels.isEmpty) return;
  app.defaultLanguage =
      app.labels.containsKey('en') ? 'en' : app.labels.keys.first;
  final keys = app.defaultLabels.keys.toSet();
  for (final MapEntry(key: language, value: labels) in app.labels.entries) {
    for (final missing in keys.difference(labels.keys.toSet())) {
      issues.warn('app/views/labels/$language.yaml', '$language.$missing',
          'missing; falls back to ${app.defaultLanguage}');
    }
  }
}

/// Reads every file in [folder] and returns each file's single top-level key
/// mapped to its value. Validates that each file has exactly one key and that
/// the key is a valid identifier not used in another file.
Map<String, dynamic> _readSingleParents(
    _FolderReader reader, String folder, Issues issues, RegExp keyCase,
    {Map<String, String>? fileOf}) {
  final out = <String, dynamic>{};
  fileOf ??= <String, String>{};
  for (final entry in reader.files(folder, required: false).entries) {
    final doc = entry.value;
    if (doc is! Map) {
      issues.error(entry.key, '', 'must be a map');
      continue;
    }
    if (doc.length != 1) {
      issues.error(entry.key, '',
          'must contain exactly one top-level key (found ${doc.keys.join(', ')})');
      continue;
    }
    final key = doc.keys.first.toString();
    if (!isValidName(key) || !keyCase.hasMatch(key)) {
      issues.error(entry.key, key, 'invalid name; use '
          '${keyCase == pascalCase ? 'ThisCase' : 'thisCase'}');
      continue;
    }
    if (baseName(entry.key) != snakeCase(key)) {
      issues.error(entry.key, key,
          'the file must be named after its key: ${snakeCase(key)}.yaml');
    }
    final other = fileOf[key];
    if (other != null) {
      issues.error(entry.key, key, 'also defined in $other');
      continue;
    }
    fileOf[key] = entry.key;
    out[key] = doc[key];
  }
  return out;
}

class _Widgets {
  final Map<String, dynamic> widgets;
  final Map<String, String> fileOf;
  _Widgets(this.widgets, this.fileOf);
}

/// Reads `app/views/pages/*.yaml` or `app/views/components/*.yaml`: one `ThisCase`
/// widget per file, named after it.
_Widgets _readWidgets(_FolderReader reader, String folder, Issues issues) {
  final fileOf = <String, String>{};
  final widgets =
      _readSingleParents(reader, folder, issues, pascalCase, fileOf: fileOf);
  return _Widgets(widgets, fileOf);
}

/// Reads the `.yaml` files of an app's folders.
class _FolderReader {
  final AppProject app;
  final Issues issues;

  _FolderReader(this.app, this.issues);

  /// Every `.yaml` in [folder], by file (`app/views/pages/main_page.yaml`),
  /// as plain Dart. When [recursive] is true, sub-folders are scanned too.
  Map<String, dynamic> files(String folder,
      {bool required = true, bool recursive = false}) {
    final skip = app.dir.isEmpty ? 0 : app.dir.length + 1;
    final found = [
      for (final f in app.files.list(app.at(folder), recursive: recursive))
        if (f.endsWith('.yaml')) f.substring(skip),
    ];
    if (found.isEmpty) {
      if (required) {
        issues.error('$folder/', '', 'missing');
      }
      return {};
    }
    return {
      for (final f in found) f: _readYaml(app.files, app.at(f), f, issues),
    };
  }

  /// Reads a single file relative to the app directory, returning null if it
  /// does not exist or cannot be parsed.
  dynamic single(String file) {
    return _readYaml(app.files, app.at(file), file, issues);
  }

  /// The files of [folder] merged into one map. With [under], each file
  /// holds its map under that key (`state:`). When [recursive] is true,
  /// sub-folders are scanned too.
  Map<String, dynamic> merged(String folder,
      {String? under, bool required = true, bool recursive = false}) {
    final out = <String, dynamic>{};
    final fileOf = <String, String>{};
    for (final entry
        in files(folder, required: required, recursive: recursive).entries) {
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

dynamic _readYaml(ProjectFiles files, String path, String label, Issues issues) {
  final source = files.read(path);
  if (source == null) return null;
  try {
    return _plain(loadYaml(source));
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

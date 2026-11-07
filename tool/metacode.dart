// Metacode CLI: validates the project and generates what the engine runs.
//
//   dart run tool/metacode.dart          validate + generate
//   dart run tool/metacode.dart check    validate only
//
// Steps: models.yaml -> state.yaml (against the `state` model) -> actions and
// bindings (signatures) -> ui.yaml -> navigation.yaml (optional, routes) ->
// style.yaml (optional, design tokens) -> generated/state.dart (+ StateDelta),
// generated/core.dart (Core, Routes), generated/main.dart -> compiled
// generated/program.evc + generated/manifest.json, and
// generated/test_app.dart (typed test harness for metacode/test/).

import 'dart:convert';
import 'dart:io';

import 'package:app_ui/style.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:metacode/engine/host_plugin.dart';
import 'package:metacode/engine/navigation.dart';
import 'package:yaml/yaml.dart';

import 'src/codegen.dart';
import 'src/functions.dart';
import 'src/issues.dart';
import 'src/models.dart';
import 'src/ui.dart';

const projectDir = 'metacode';

void main(List<String> args) {
  final checkOnly = args.contains('check');
  final issues = Issues();
  final root = Directory(projectDir);

  dynamic readYaml(String name) {
    final file = File('$projectDir/$name');
    if (!file.existsSync()) {
      issues.error(name, '', 'file not found');
      return null;
    }
    try {
      return loadYaml(file.readAsStringSync());
    } on YamlException catch (e) {
      issues.error(name, '', e.message);
      return null;
    }
  }

  final models = parseModels(readYaml('models.yaml'), issues);
  validateState(readYaml('state.yaml'), models, issues);

  final actions = readFunctions(
      Directory('${root.path}/actions'), 'actions', models, issues);
  final bindings = readFunctions(
      Directory('${root.path}/bindings'), 'bindings', models, issues);

  final seen = <String, String>{};
  for (final fn in [...actions, ...bindings]) {
    final other = seen[fn.name];
    if (other != null) {
      issues.error(fn.file, fn.name, 'also defined in $other; names must be unique');
    }
    seen[fn.name] = fn.file;
  }

  final ui = readYaml('ui.yaml');
  final hasNavigation = File('$projectDir/navigation.yaml').existsSync();
  validateUi(
    ui,
    bindings.map((f) => f.name).toSet(),
    actions.map((f) => f.name).toSet(),
    issues,
    requireHomePage: !hasNavigation,
  );

  var navigation = Navigation.fallback;
  if (hasNavigation) {
    final parsed = Navigation.parse(readYaml('navigation.yaml'),
        (path, message) => issues.error('navigation.yaml', path, message));
    final widgets = ui is Map && ui['widgets'] is Map ? ui['widgets'] as Map : {};
    for (final route in parsed?.routes.values ?? const <RouteSpec>[]) {
      if (!widgets.containsKey(route.widget)) {
        issues.error('navigation.yaml', 'routes.${route.name}',
            '"${route.widget}" is not a widget in ui.yaml');
      }
    }
    navigation = parsed ?? navigation;
  }

  if (File('$projectDir/style.yaml').existsSync()) {
    for (final (path, message) in validateStyle(readYaml('style.yaml'))) {
      issues.error('style.yaml', path, message);
    }
  }

  if (!issues.hasErrors && !checkOnly) {
    _generate(root, models, actions, bindings, navigation, issues);
  }

  for (final w in issues.warnings) {
    stderr.writeln('warning: $w');
  }
  for (final e in issues.errors) {
    stderr.writeln('error: $e');
  }
  if (issues.hasErrors) {
    stderr.writeln('\n${issues.errors.length} error(s).');
    exit(1);
  }
  stdout.writeln(checkOnly
      ? 'OK: project is valid.'
      : 'OK: ${actions.length} actions, ${bindings.length} bindings -> '
          '$projectDir/generated/');
}

void _generate(
  Directory root,
  Map<String, Model> models,
  List<UserFunction> actions,
  List<UserFunction> bindings,
  Navigation navigation,
  Issues issues,
) {
  final userFiles = {
    for (final fn in [...actions, ...bindings]) fn.file,
  }.toList()
    ..sort();

  final generated = {
    'generated/state.dart': generateState(models),
    'generated/core.dart': generateCore(navigation.routes.keys),
    'generated/main.dart': generateMain(actions, bindings, userFiles, models),
    'generated/test_app.dart': generateTestApp(actions, bindings, models),
  };

  final outDir = Directory('${root.path}/generated')..createSync();
  generated.forEach((path, code) => File('${root.path}/$path').writeAsStringSync(code));

  // The engine runs one bundled library. dart_eval mis-resolves some calls
  // across libraries (e.g. an action calling a binding), so user files stay
  // separate for editing and are merged here for execution.
  final bundle = _bundle([
    generated['generated/state.dart']!,
    generated['generated/core.dart']!,
    for (final f in _allDartFiles(root, ['actions', 'bindings']))
      File('${root.path}/$f').readAsStringSync(),
    generated['generated/main.dart']!,
  ]);
  // (test_app.dart runs on the host, not in the interpreter.)

  try {
    final program = (Compiler()..addPlugin(const HostPlugin())).compile({
      'metacode': {'main.dart': bundle},
    });
    File('${outDir.path}/program.evc').writeAsBytesSync(program.write());
  } catch (e) {
    issues.error('actions/bindings', '',
        'could not compile for the engine (dart_eval): $e');
    return;
  }

  final manifest = {
    'actions': [for (final f in actions) f.name],
    'bindings': [for (final f in bindings) f.name],
  };
  File('${outDir.path}/manifest.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
}

/// Merges Dart sources into one library: relative imports are dropped (all
/// code ends up in the same file); `dart:` imports and the engine host
/// bridge (see lib/engine/host.dart) are kept once.
String _bundle(List<String> sources) {
  final imports = <String>{"import 'dart:convert';"};
  final bodies = <String>[];
  for (final source in sources) {
    final body = <String>[];
    for (final line in source.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('import ')) {
        if (trimmed.contains("'dart:") ||
            trimmed.contains("'${HostPlugin.library}'")) {
          imports.add(trimmed);
        }
        continue;
      }
      body.add(line);
    }
    bodies.add(body.join('\n'));
  }
  return '${imports.join('\n')}\n\n${bodies.join('\n')}';
}

/// All .dart files under the given folders, relative to [root].
List<String> _allDartFiles(Directory root, List<String> folders) {
  return [
    for (final folder in folders)
      if (Directory('${root.path}/$folder').existsSync())
        for (final f in Directory('${root.path}/$folder')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')))
          f.path.substring(root.path.length + 1),
  ];
}

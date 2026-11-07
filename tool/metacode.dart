// Metacode CLI: validates the project and generates what the engine runs.
//
//   dart run tool/metacode.dart          validate + generate
//   dart run tool/metacode.dart check    validate only
//
// An app is a folder (see tool/src/project.dart): app.yaml plus models/,
// state/, ui/, navigation/, style/ (every .yaml in a folder is merged),
// actions/ and relations/ (Dart), test/, and sub-apps in apps/<name>/, which
// are apps themselves (recursive).
//
// Per app: models -> state (against the `state` model) -> actions and
// relations (signatures) -> ui (widgets, and `app:` names against apps/) ->
// navigation (optional) -> style (optional). Then, per app:
// generated/state.dart (+ StateDelta), generated/core.dart (Core, Routes),
// generated/main.dart, compiled generated/program.evc + manifest.json, and
// generated/test_app.dart (typed test harness for its test/). The root also
// gets generated/bundle.json: the whole app tree, which the engine loads as
// its only asset (besides images).

import 'dart:convert';
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:metacode/engine/host_plugin.dart';

import 'src/codegen.dart';
import 'src/issues.dart';
import 'src/project.dart';

const projectDir = 'metacode';

void main(List<String> args) {
  final checkOnly = args.contains('check');
  final issues = Issues();

  final root = loadApp(Directory(projectDir), projectDir, issues);

  if (!issues.hasErrors && !checkOnly) {
    final bundle = _generate(root, issues);
    if (bundle != null && !issues.hasErrors) {
      File('$projectDir/generated/bundle.json')
          .writeAsStringSync(jsonEncode(bundle));
    }
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
  final apps = root.tree.toList();
  stdout.writeln(checkOnly
      ? 'OK: ${apps.length} app(s) valid.'
      : 'OK: ${apps.map((a) => '${a.label}: ${a.actions.length} actions, '
          '${a.bindings.length} relations').join('; ')} -> generated/');
}

/// Generates [app] and its sub-apps; returns its bundle node (null if
/// compiling failed).
Map<String, dynamic>? _generate(AppProject app, Issues issues) {
  final apps = <String, dynamic>{};
  for (final child in app.apps.values) {
    final node = _generate(child, issues);
    if (node == null) return null;
    apps[child.name] = node;
  }

  final dir = app.dir.path;
  final userFiles = {
    for (final fn in [...app.actions, ...app.bindings]) fn.file,
  }.toList()
    ..sort();

  final generated = {
    'generated/state.dart': generateState(app.models),
    'generated/core.dart': generateCore(app.navigation.routes.keys),
    'generated/main.dart':
        generateMain(app.actions, app.bindings, userFiles, app.models),
    'generated/test_app.dart':
        generateTestApp(app.actions, app.bindings, app.models, app.path),
  };

  final outDir = Directory('$dir/generated')..createSync();
  generated.forEach((path, code) => File('$dir/$path').writeAsStringSync(code));

  // The engine runs one bundled library per app. dart_eval mis-resolves some
  // calls across libraries (e.g. an action calling a relation), so user files
  // stay separate for editing and are merged here for execution.
  final bundle = _bundle([
    generated['generated/state.dart']!,
    generated['generated/core.dart']!,
    for (final f in _allDartFiles(app.dir, ['actions', 'relations']))
      File('$dir/$f').readAsStringSync(),
    generated['generated/main.dart']!,
  ]);
  // (test_app.dart runs on the host, not in the interpreter.)

  final List<int> bytecode;
  try {
    final program = (Compiler()..addPlugin(const HostPlugin())).compile({
      'metacode': {'main.dart': bundle},
    });
    bytecode = program.write();
    File('${outDir.path}/program.evc').writeAsBytesSync(bytecode);
  } catch (e) {
    issues.scoped(app.prefix).error('actions/relations', '',
        'could not compile for the engine (dart_eval): $e');
    return null;
  }

  final manifest = {
    'actions': [for (final f in app.actions) f.name],
    'bindings': [for (final f in app.bindings) f.name],
  };
  File('${outDir.path}/manifest.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n');

  return {
    'name': app.title,
    'description': app.description,
    'ui': {'widgets': app.widgets},
    'state': app.state,
    'navigation': app.navigationDoc,
    'style': app.styleDoc,
    'manifest': manifest,
    'program': base64Encode(bytecode),
    'apps': apps,
  };
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
        for (final f in (Directory('${root.path}/$folder')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))
                .toList()
              ..sort((a, b) => a.path.compareTo(b.path))))
          f.path.substring(root.path.length + 1),
  ];
}

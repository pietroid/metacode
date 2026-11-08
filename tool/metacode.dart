// Metacode CLI: validates the project and generates what the engine runs.
//
//   dart run tool/metacode.dart          validate + generate
//   dart run tool/metacode.dart check    validate only
//   dart run tool/metacode.dart watch    validate + generate on every change
//   dart run tool/metacode.dart <folder> another app folder (default
//                                        examples/my_own_app), e.g. the
//                                        engine's test/fixture_app
//
// The work itself is lib/compiler/build.dart, on the project's files in
// memory (lib/files/): the running app does the same on every change, so
// `watch` only keeps the .generated/ files fresh for the IDE and tests.
// See build.dart for what is validated and generated, and
// lib/compiler/project.dart for an app's layout.

import 'dart:async';
import 'dart:io';

import 'package:metacode/compiler/build.dart';
import 'package:metacode/files/io_project_files.dart';
import 'package:metacode/files/project_files.dart';

late final String projectDir;

Future<void> main(List<String> args) async {
  projectDir = args
      .firstWhere((a) => a != 'watch' && a != 'check',
          orElse: () => 'examples/my_own_app')
      .replaceFirst(RegExp(r'/$'), '');
  final watch = args.contains('watch');
  final files = await IoProjectFiles.open(projectDir, watch: watch);
  if (watch) return _watch(files);
  if (!await _run(files, checkOnly: args.contains('check'))) exit(1);
}

/// Validates (and unless [checkOnly], generates) the project, printing the
/// issues. Returns whether it is valid.
Future<bool> _run(ProjectFiles files, {bool checkOnly = false}) async {
  final result = build(files, path: projectDir, checkOnly: checkOnly);
  await result.writeTo(files);

  final issues = result.issues;
  for (final w in issues.warnings) {
    stderr.writeln('warning: $w');
  }
  for (final e in issues.errors) {
    stderr.writeln('error: $e');
  }
  if (issues.hasErrors) {
    stderr.writeln('\n${issues.errors.length} error(s).');
    return false;
  }
  final apps = result.root.tree.toList();
  stdout.writeln(checkOnly
      ? 'OK: ${apps.length} app(s) valid.'
      : 'OK: ${apps.map((a) => '${a.label}: ${a.actions.length} actions, '
          '${a.bindings.length} values').join('; ')} -> .generated/');
  return true;
}

/// Generates now and again after every change to the project's sources.
/// Runs stay in this process, so after the first one the compiler is warm.
Future<void> _watch(ProjectFiles files) async {
  await _run(files);
  stdout.writeln('metacode: watching $projectDir');
  Timer? pending;
  await for (final paths in files.changes) {
    final sources = paths.where(ProjectFiles.isSource).toList();
    if (sources.isEmpty) continue;
    // An editor save is often several events; generate once after them.
    pending?.cancel();
    pending = Timer(const Duration(milliseconds: 200), () async {
      final watch = Stopwatch()..start();
      stdout.writeln('\nmetacode: ${sources.first} changed');
      if (await _run(files)) stdout.writeln('(${watch.elapsedMilliseconds}ms)');
      stdout.writeln('metacode: watching $projectDir');
    });
  }
}

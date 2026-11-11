// validate (fast, per file, safe to run from many agents) and check (the
// whole app: tests and layout, once, by the orchestrator).

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:metacode/compiler/build.dart';
import 'package:metacode/files/io_project_files.dart';

import 'plan.dart';
import 'scaffold.dart';

AnalysisContextCollection? _analysis;
String? _analysisRoot;

/// Builds the app in memory (every validation the tool does, and the
/// dart_eval compile), writes the generated Dart files the user files import,
/// then type-checks [only] (the .dart files among them) with a warm analyzer.
/// Issues are filtered to [only] when given; the rest is counted.
Future<String> validate(String app, {List<String> only = const []}) async {
  final watch = Stopwatch()..start();
  // Accept repo-relative paths too (examples/travel/app/x.dart).
  only = [for (final f in only) f.startsWith('$app/') ? f.substring(app.length + 1) : f];
  final missing = only.where((f) => !File('$app/$f').existsSync() && !Directory('$app/$f').existsSync()).toList();
  if (missing.isNotEmpty) {
    return 'ERROR: no such file in $app: ${missing.join(', ')}. Pass paths relative to the app (app/actions/x.dart).';
  }
  final files = await IoProjectFiles.open(app);
  final result = build(files, path: app);
  // Only the generated Dart (state, core, labels, remote, test harness) and
  // the index: stable while the contract doesn't change, so parallel
  // validations don't fight over the bytecode.
  for (final MapEntry(key: path, value: contents) in result.outputs.entries) {
    if (contents is String && (path.endsWith('.dart') || path.endsWith('INDEX.md'))) {
      await files.write(path, contents);
    }
  }

  // An issue with no file (the dart_eval compile of all user code) is
  // everyone's: shown to every caller.
  bool mine(String issue) =>
      only.isEmpty ||
      !issue.startsWith('app/') ||
      only.any((f) => issue.startsWith(f) || issue.contains(' $f'));
  final errors = result.issues.errors.where(mine).toList();
  final warnings = result.issues.warnings.where(mine).toList();
  final others = result.issues.errors.length - errors.length;

  final typeErrors = <String>[];
  final dartFiles = only.where((f) => f.endsWith('.dart')).toList();
  if (dartFiles.isNotEmpty) {
    typeErrors.addAll(await _typeCheck(app, dartFiles));
  }

  final stubs = only.where((f) => isStub('$app/$f')).toList();
  final out = StringBuffer();
  if (errors.isEmpty && typeErrors.isEmpty) {
    out.write(only.isEmpty ? 'OK: the app is valid' : 'OK: ${only.length} file(s) valid');
  } else {
    out.writeln('${errors.length + typeErrors.length} error(s):');
    for (final e in [...errors, ...typeErrors]) {
      out.writeln('- $e');
    }
  }
  for (final w in warnings) {
    out.writeln('\nwarning: $w');
  }
  if (stubs.isNotEmpty) out.write('\nstill stubs (remove the `$stubMarker` line when done): ${stubs.join(', ')}');
  if (others > 0) out.write('\n($others error(s) in other files, not yours: ignore them)');
  out.write(' [${watch.elapsedMilliseconds}ms]');
  return out.toString().trim();
}

Future<List<String>> _typeCheck(String app, List<String> rel) async {
  final root = Directory(app).absolute.path;
  if (_analysis == null || _analysisRoot != root) {
    _analysis = AnalysisContextCollection(includedPaths: [root]);
    _analysisRoot = root;
  }
  final out = <String>[];
  final gen = Directory('$root/.generated');
  final changed = [
    for (final f in rel) '$root/$f',
    if (gen.existsSync())
      for (final f in gen.listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) f.path,
    '$root/app/models/sample.dart',
  ];
  for (final f in rel) {
    final path = '$root/$f';
    if (!File(path).existsSync()) {
      out.add('$f: no such file');
      continue;
    }
    final context = _analysis!.contextFor(path);
    for (final c in changed) {
      context.changeFile(c);
    }
    await context.applyPendingFileChanges();
    final result = await context.currentSession.getErrors(path);
    if (result is! ErrorsResult) continue;
    for (final d in result.diagnostics) {
      if (!'${d.severity}'.toLowerCase().contains('error')) continue;
      final line = result.lineInfo.getLocation(d.offset).lineNumber;
      out.add('$f > line $line: ${d.message}');
    }
  }
  return out;
}

/// The whole app: generate, then every test (the main() of each action and
/// value) and the layout check (every route at phone, tablet and desktop,
/// plus tests/*.yaml states). Failures grouped by file, errors trimmed.
Future<String> check(String app, {List<String> only = const [], bool layoutOnly = false}) async {
  only = [for (final f in only) f.startsWith('$app/') ? f.substring(app.length + 1) : f];
  final watch = Stopwatch()..start();
  final files = await IoProjectFiles.open(app);
  final result = build(files, path: app);
  await result.writeTo(files);
  if (result.issues.hasErrors) {
    return 'FAIL: ${result.issues.errors.length} validation error(s):\n'
        '${result.issues.errors.map((e) => '- $e').join('\n')}';
  }
  // Lint as the repo's `flutter analyze` does: fix what is mechanical,
  // report the rest (warnings and errors) with the tests.
  if (only.isEmpty && !layoutOnly) await Process.run('dart', ['fix', '--apply', app]);
  final lint = only.isEmpty && !layoutOnly
      ? [
          for (final l in ((await Process.run('dart', ['analyze', '--format=machine', app])).stderr as String).split('\n'))
            if (l.startsWith('ERROR|') || l.startsWith('WARNING|')) _lintLine(app, l),
        ]
      : const <String>[];
  final stubs = [
    for (final f in Directory(app).listSync(recursive: true).whereType<File>())
      if (!f.path.contains('/.') && isStub(f.path)) f.path.substring(app.length + 1),
  ];

  final proc = await Process.run('flutter', [
    'test',
    '--reporter',
    'json',
    '--dart-define=METACODE_APP=$app',
    // Only some files: their tests (all_test groups are their paths), no
    // layout check. Only the layout: no tests.
    if (!layoutOnly) '$app/.generated/all_test.dart',
    if (only.isEmpty) 'tool/layout_test.dart',
    if (only.isNotEmpty) ...['--name', '^(${only.map(RegExp.escape).join('|')}) '],
  ]);
  final names = <int, String>{};
  final groups = <int, String>{};
  final failures = <String, List<String>>{};
  var passed = 0;
  var total = 0;
  final loose = <String>[];
  for (final line in (proc.stdout as String).split('\n')) {
    if (!line.startsWith('{')) {
      if (line.trim().isNotEmpty && line.contains('Error')) loose.add(line.trim());
      continue;
    }
    final Map<String, dynamic> e;
    try {
      e = jsonDecode(line) as Map<String, dynamic>;
    } on FormatException {
      continue;
    }
    switch (e['type']) {
      case 'group':
        final g = e['group'] as Map;
        groups[g['id'] as int] = '${g['name']}';
      case 'testStart':
        final t = e['test'] as Map;
        names[t['id'] as int] = '${t['name']}';
      case 'error':
        final name = names[e['testID']] ?? 'test ${e['testID']}';
        failures.putIfAbsent(name, () => []).add(_trim('${e['error']}', '${e['stackTrace']}'));
      case 'testDone':
        if (e['hidden'] == true) break;
        total++;
        if (e['result'] == 'success') passed++;
    }
  }
  final out = StringBuffer();
  final secs = (watch.elapsedMilliseconds / 1000).toStringAsFixed(1);
  if (lint.isNotEmpty) {
    failures['analyze'] = [lint.join('\n')];
  }
  if (failures.isEmpty && proc.exitCode == 0) {
    out.write(layoutOnly ? 'OK: $passed layout checks passed (every route and test state at 4 sizes) [${secs}s]' : only.isEmpty ? 'OK: $passed tests and layout checks passed [${secs}s]' : 'OK: $passed test(s) of ${only.length} file(s) passed [${secs}s]');
  } else {
    out.writeln('FAIL: ${failures.length} failing of $total [${secs}s]');
    // One dart_eval runtime crash leaves the shared program broken, and every
    // later action test fails the same way: show the first in full, name the
    // rest.
    final crashes = [
      for (final MapEntry(key: name, value: errs) in failures.entries)
        if (errs.any((e) => e.contains('dart_eval runtime exception'))) name,
    ];
    if (crashes.length > 1) {
      out.writeln('\nNOTE: ${crashes.length} tests crashed in dart_eval. Usually the FIRST one '
          '(${crashes.first}) is the cause and the rest are collateral: fix it, check again.');
      for (final n in crashes.skip(1)) {
        failures[n] = ['(collateral of the first crash?)'];
      }
    }
    // Group by the file the failure belongs to (all_test groups are paths).
    final byFile = <String, List<String>>{};
    for (final MapEntry(key: name, value: errs) in failures.entries) {
      final m = RegExp(r'^(app/\S+\.dart) (.*)$').firstMatch(name);
      final file = m?[1] ?? (name.startsWith('loading') ? 'compile' : 'layout');
      byFile.putIfAbsent(file, () => []).add('${m?[2] ?? name}: ${errs.join('\n')}');
    }
    for (final MapEntry(key: file, value: items) in byFile.entries) {
      out.writeln('\n## $file');
      for (final i in items) {
        out.writeln('- $i');
      }
    }
    if (failures.isEmpty) {
      out.writeln(loose.take(30).join('\n'));
      out.writeln((proc.stderr as String).split('\n').take(30).join('\n'));
    }
  }
  if (only.isEmpty && !layoutOnly && stubs.isEmpty) {
    final unused = _unusedPlanned(app);
    if (unused.isNotEmpty) {
      out.write('\n\nplanned but never used (remove them from the plan and their files, or use them): ${unused.join(', ')}');
    }
  }
  if (stubs.isNotEmpty && only.isEmpty && !layoutOnly) out.write('\n\nstill stubs: ${stubs.join(', ')}');
  return out.toString().trim();
}

/// `SEVERITY|TYPE|CODE|path|line|col|len|message` -> `path:line: message`.
String _lintLine(String app, String line) {
  final f = line.split('|');
  final abs = Directory(app).absolute.path;
  final path = f[3].startsWith('$abs/') ? f[3].substring(abs.length + 1) : f[3];
  return '$path:${f[4]}: ${f.sublist(7).join('|')} (${f[2].toLowerCase()})';
}

/// The error and the first frames from user code, without the noise.
String _trim(String error, String stack) {
  final lines = error.split('\n').where((l) => l.trim().isNotEmpty).toList();
  final head = lines.length > 14 ? [...lines.take(14), '…'] : lines;
  final frames = stack
      .split('\n')
      .where((l) => l.contains('/app/') && !l.contains('.generated'))
      .take(2);
  return [...head, ...frames].map((l) => '  $l').join('\n').trimLeft();
}

/// Planned values, actions and components no other file names (a view, an
/// action, the start action): planned work nobody shows.
List<String> _unusedPlanned(String app) {
  final Plan plan;
  try {
    plan = Plan.load(app);
  } on Object {
    return const [];
  }
  final sources = <String, String>{
    for (final f in Directory('$app/app').listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.yaml') || f.path.endsWith('.dart')) f.path.substring(app.length + 1): f.readAsStringSync(),
    'app.yaml': File('$app/app.yaml').existsSync() ? File('$app/app.yaml').readAsStringSync() : '',
  };
  bool named(String name, String ownFile) {
    final word = RegExp('\\b$name\\b');
    return sources.entries.any((e) => e.key != ownFile && word.hasMatch(e.value.split('\nvoid main(').first));
  }
  return [
    for (final c in plan.code.values)
      if (c.kind == 'action' || c.kind == 'value')
        if (!named(c.name, c.file)) c.name,
    for (final v in plan.components)
      if (!named(v.name, v.file)) v.name,
  ];
}

// Scaffold: from the plan, a stub for every unit that already compiles
// (header comment, signature, imports, a placeholder body, a test
// skeleton), plus app/models/sample.dart and tests/*.yaml. Existing files
// are kept unless they are still stubs, so it can run again after the plan
// changes.

import 'dart:convert';
import 'dart:io';

import 'package:metacode/compiler/issues.dart' show snakeCase;
import 'package:yaml/yaml.dart';

import 'plan.dart';

/// The line every stub carries until an agent fills it.
const stubMarker = 'TODO(metacode): stub';

bool isStub(String path) {
  final f = File(path);
  return f.existsSync() && f.readAsStringSync().contains(stubMarker);
}

/// Writes the stubs; returns the files written.
List<String> scaffold(Plan plan) {
  final written = <String>[];
  final models = _models(plan.app);

  void put(String rel, String contents, {bool keepExisting = false}) {
    final f = File('${plan.app}/$rel');
    if (f.existsSync()) {
      if (keepExisting || !f.readAsStringSync().contains(stubMarker)) return;
      if (f.readAsStringSync() == contents) return;
    }
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(contents);
    written.add(rel);
  }

  for (final v in plan.views.values) {
    put(v.file, _viewStub(v));
  }
  for (final c in plan.code.values) {
    put(c.file, _codeStub(c, plan, models));
  }
  put('app/models/sample.dart', _sample, keepExisting: true);
  for (final MapEntry(key: name, value: t) in plan.tests.entries) {
    put('tests/${snakeCase(name)}.yaml', _testState(name, t), keepExisting: true);
  }
  return written;
}

String _wrap(String prefix, String text) {
  final out = StringBuffer();
  var line = prefix;
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    if (line.length + word.length + 1 > 78 && line.trim() != prefix.trim()) {
      out.writeln(line.trimRight());
      line = '${prefix.split(' ').first} ';
    }
    line += line.endsWith(' ') ? word : ' $word';
  }
  out.writeln(line.trimRight());
  return out.toString();
}

String _viewStub(ViewUnit v) {
  final header = _wrap('# ${v.name}:', v.purpose.isEmpty ? 'TODO' : v.purpose);
  // Every parameter is used once, in a prop of its kind, so callers
  // written against the plan validate before the component is designed.
  final uses = [
    for (final MapEntry(key: p, value: kind) in v.params.entries)
      switch (kind) {
        'text' => '{text: .$p}',
        'icon' => '{icon: {name: .$p}}',
        'action' => '{iconButton: {icon: add, onPressed: .$p}}',
        'color' => '{container: {color: .$p}}',
        'number' => '{container: {opacity: .$p}}',
        'literal' => '{sizedBox: {width: .$p}}',
        _ => '.$p',
      },
  ];
  final body = uses.isEmpty ? 'sizedBox: {}' : 'column: [${uses.join(', ')}]';
  return '$header# $stubMarker\n${v.name}:\n  $body\n';
}

/// app/models/*.yaml: enum name (Dart) -> first value; model names (Dart).
({Map<String, String> enums, Set<String> classes}) _models(String app) {
  final enums = <String, String>{};
  final classes = <String>{};
  final dir = Directory('$app/app/models');
  if (!dir.existsSync()) return (enums: enums, classes: classes);
  for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml'))) {
    final y = loadYaml(f.readAsStringSync());
    if (y is! YamlMap || y.isEmpty) continue;
    final name = '${y.keys.first}';
    final dart = name[0].toUpperCase() + name.substring(1);
    final v = y.values.first;
    if (v is YamlList && v.isNotEmpty) {
      enums[dart] = '${v.first}';
    } else {
      classes.add(dart);
    }
  }
  return (enums: enums, classes: classes);
}

String _placeholder(String type, ({Map<String, String> enums, Set<String> classes}) models) {
  type = type.trim();
  if (type.endsWith('?') || type == 'dynamic') return 'null';
  if (type == 'String') return "''";
  if (type == 'bool') return 'false';
  if (type == 'num' || type == 'int') return '0';
  if (type == 'double') return '0.0';
  if (type.startsWith('List')) return '[]';
  if (type.startsWith('Map')) return '{}';
  if (type == 'DateTime') return 'DateTime(2000)';
  final first = models.enums[type];
  if (first != null) return '$type.$first';
  return "throw 'stub'";
}

String _codeStub(CodeUnit c, Plan plan, ({Map<String, String> enums, Set<String> classes}) models) {
  final header = _wrap('// ${c.name}:', c.purpose.isEmpty ? 'TODO' : c.purpose);
  final out = StringBuffer(header)..writeln('// $stubMarker');
  final up = c.kind == 'value' ? '../../../' : (c.kind == 'action' ? '../../' : '../../../');
  final sharedUp = c.kind == 'shared' && c.sharedIn == 'values' ? '../../../../' : up;
  final testable = c.kind == 'action' || c.kind == 'value';

  // Imports.
  final imports = <String>[
    if (testable) "import 'package:flutter_test/flutter_test.dart';",
    if (c.params.contains('core')) "import '$up.generated/core.dart';",
    if (c.params.contains('labels')) "import '$up.generated/labels.dart';",
    if (c.params.contains('remote')) "import '$up.generated/remote.dart';",
    if (c.kind == 'remote') "import '$up.generated/remote_state.dart';",
    if (c.kind == 'action' || c.kind == 'value') "import '$up.generated/state.dart';",
    if (c.kind == 'shared') "import '$sharedUp.generated/state.dart';",
    if (c.kind == 'action') "import '../models/sample.dart';",
    if (c.kind == 'value') "import '../../models/sample.dart';",
  ];
  for (final u in c.uses) {
    final s = plan.code[u];
    if (s == null || s.kind != 'shared') continue;
    imports.add("import '${_relative(c.file, s.file)}';");
  }
  imports.sort((a, b) {
    final pa = a.contains('package:') ? 0 : 1;
    final pb = b.contains('package:') ? 0 : 1;
    return pa != pb ? pa - pb : a.compareTo(b);
  });
  out
    ..writeln()
    ..writeAll(imports, '\n')
    ..writeln()
    ..writeln();

  // Body.
  switch (c.kind) {
    case 'value':
      final p = _placeholder(c.returns, models);
      out.writeln(p.startsWith('throw')
          ? '${c.declaration} {\n  $p;\n}'
          : '${c.declaration} => $p;');
    case 'shared':
      final ret = RegExp(r'^\s*([\w<>?, ]+?)\s+\w+\s*\(').firstMatch(c.signature)?[1] ?? 'void';
      final p = _placeholder(ret, models);
      out.writeln(ret == 'void'
          ? '${c.signature} {}'
          : (p.startsWith('throw') ? '${c.signature} {\n  $p;\n}' : '${c.signature} => $p;'));
    default:
      out.writeln('${c.declaration} {}');
  }

  if (testable) {
    out
      ..writeln()
      ..writeln('void main() {')
      ..writeln("  test('${c.name}', () async {")
      ..writeln('    // ${c.test.isEmpty ? 'TODO' : c.test.replaceAll('\n', ' ')}')
      ..writeln('    // e.g. final s = await ${c.testCall};')
      ..writeln('  });')
      ..writeln('}');
  }
  return out.toString();
}

String _relative(String from, String to) {
  final a = from.split('/')..removeLast();
  final b = to.split('/');
  var i = 0;
  while (i < a.length && i < b.length - 1 && a[i] == b[i]) {
    i++;
  }
  return [for (var j = i; j < a.length; j++) '..', ...b.sublist(i)].join('/');
}

const _sample = '''// sample: test fixtures. `app` runs actions and values through the compiled
// program, like the engine. `sample()` is the initial state from app.yaml;
// `sample({'field': value})` changes fields, written as JSON (as in app.yaml).
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

final app = TestApp();

State sample([Map<String, dynamic> changes = const {}]) =>
    State.fromJson({...app.initialState.toJson(), ...changes});
''';

String _testState(String name, Map t) =>
    // JSON is YAML: one line, no indentation to get wrong.
    '# $name: a layout check state from the plan.\n$name: ${jsonEncode(_plain(t))}\n';

Object? _plain(Object? v) => v is Map
    ? {for (final e in v.entries) '${e.key}': _plain(e.value)}
    : v is List
        ? [for (final x in v) _plain(x)]
        : v;

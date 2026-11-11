// The plan: an app's work units, decided before any of them is written.
//
// `<app>/plan.yaml` lists every page, component, action, remote action,
// value, shared helper and test state with its purpose and its contract
// (params, return type, what it uses). The contract files (app.yaml,
// app/models/, app/views/labels/en.yaml, app/views/navigation.yaml) are
// written by the planner directly. From both, the scaffold writes a stub
// per unit that already compiles, and the briefs hand groups of units to
// agents that fill them in parallel: no two agents touch the same file.
//
// See .claude/skills/metacode-new-app/PLAN.md for the format.

import 'dart:io';

import 'package:metacode/compiler/issues.dart' show snakeCase;
import 'package:yaml/yaml.dart';

/// One page or component.
class ViewUnit {
  final String name;
  final bool page;
  final String purpose;

  /// Component parameters: `.name` -> prop kind (text, icon, action, color,
  /// number, node, literal).
  final Map<String, String> params;

  /// Components, values, actions and labels it shows or runs.
  final List<String> uses;

  ViewUnit(this.name, this.page, this.purpose, this.params, this.uses);

  String get file =>
      'app/views/${page ? 'pages' : 'components'}/${snakeCase(name)}.yaml';
}

/// One action, remote action, value or shared helper.
class CodeUnit {
  /// action | remote | value | shared
  final String kind;
  final String name;
  final String purpose;

  /// Action/value params after `State state`, by name: emit, core, remote,
  /// labels, index, value.
  final List<String> params;

  /// The type of `value` (actions and remote actions taking one).
  final String? valueType;

  /// A value's return type; a shared helper's full signature.
  final String returns;
  final String signature;

  /// Shared helpers and remote actions it calls; what its test checks.
  final List<String> uses;
  final String test;

  /// For a shared helper: `actions` or `values` (where its file lives).
  final String sharedIn;

  CodeUnit(this.kind, this.name, this.purpose,
      {this.params = const [],
      this.valueType,
      this.returns = '',
      this.signature = '',
      this.uses = const [],
      this.test = '',
      this.sharedIn = 'actions'});

  String get file => switch (kind) {
        'action' => 'app/actions/${snakeCase(name)}.dart',
        'remote' => 'app/actions/remote/${snakeCase(name)}.dart',
        'value' => 'app/views/values/${snakeCase(name)}.dart',
        _ => sharedIn == 'values'
            ? 'app/views/values/shared/${snakeCase(name)}.dart'
            : 'app/actions/shared/${snakeCase(name)}.dart',
      };

  /// The Dart parameter for each param name.
  static String dartParam(String p, String? valueType) => switch (p) {
        'emit' => 'void Function(StateDelta) emit',
        'core' => 'Core core',
        'remote' => 'Remote remote',
        'labels' => 'Labels labels',
        'index' => 'int index',
        'value' => '${valueType ?? 'String'} value',
        _ => p,
      };

  /// The declaration line (without body).
  String get declaration {
    if (kind == 'shared') return signature;
    final ps = [
      'State state',
      for (final p in params) dartParam(p, valueType),
    ].join(', ');
    if (kind == 'value') return '$returns $name($ps)';
    return 'Future<void> $name($ps) async';
  }

  /// How a test calls it: `app.name(state, index, value)`.
  String get testCall {
    final args = [
      'sample()',
      if (params.contains('index')) '0',
      if (params.contains('value')) _sampleArg(valueType ?? 'String'),
    ];
    return 'app.$name(${args.join(', ')})';
  }

  static String _sampleArg(String type) => switch (type) {
        'String' => "'x'",
        'bool' => 'true',
        'num' || 'int' || 'double' => '1',
        _ => '/* $type */',
      };
}

class Plan {
  final String app;
  final String summary;
  final String style;
  final Map<String, ViewUnit> views;
  final Map<String, CodeUnit> code;

  /// Test states: name -> {state: {...}, route: x}.
  final Map<String, Map> tests;

  Plan(this.app, this.summary, this.style, this.views, this.code, this.tests);

  Iterable<ViewUnit> get pages => views.values.where((v) => v.page);
  Iterable<ViewUnit> get components => views.values.where((v) => !v.page);
  Iterable<CodeUnit> ofKind(String k) => code.values.where((c) => c.kind == k);

  /// Code units keyed by kind+name (a remote action may share a local
  /// action's name).
  static String key(String kind, String name) =>
      kind == 'remote' ? 'remote:$name' : name;

  /// Who uses [name] (views and code).
  List<String> usedBy(String name) => [
        for (final v in views.values)
          if (v.uses.contains(name)) v.name,
        for (final c in code.values)
          if (c.uses.contains(name) && c.name != name) c.name,
      ];

  static Plan load(String appDir) {
    final file = File('$appDir/plan.yaml');
    if (!file.existsSync()) {
      throw PlanError('no plan: write $appDir/plan.yaml first (see '
          '.claude/skills/metacode-new-app/PLAN.md)');
    }
    final Object? doc;
    try {
      doc = loadYaml(file.readAsStringSync());
    } on YamlException catch (e) {
      throw PlanError('plan.yaml: ${e.message} at line ${(e.span?.start.line ?? -1) + 1} '
          '(a purpose holding ": " or starting with a quote/backtick needs quotes or `>-`)');
    }
    if (doc is! YamlMap || doc['plan'] is! YamlMap) {
      throw PlanError('plan.yaml must have one top-level key: plan');
    }
    final p = doc['plan'] as YamlMap;
    final views = <String, ViewUnit>{};
    final code = <String, CodeUnit>{};

    Map<String, YamlMap> section(String name) {
      final s = p[name];
      if (s == null) return {};
      if (s is! YamlMap) throw PlanError('plan.$name must be a map');
      return {
        for (final e in s.entries)
          '${e.key}': e.value is YamlMap
              ? e.value as YamlMap
              : (e.value is String
                  ? YamlMap.wrap({'purpose': e.value})
                  : throw PlanError('plan.$name.${e.key} must be a map')),
      };
    }

    List<String> strings(Object? v) => v == null
        ? const []
        : v is YamlList
            ? [for (final x in v) '$x']
            : ['$v'];

    for (final kind in ['pages', 'components']) {
      for (final MapEntry(:key, :value) in section(kind).entries) {
        final params = value['params'];
        views[key] = ViewUnit(
          key,
          kind == 'pages',
          '${value['purpose'] ?? ''}'.trim(),
          params is YamlMap
              ? {for (final e in params.entries) '${e.key}': '${e.value}'}
              : {for (final s in strings(params)) s: 'node'},
          strings(value['uses']),
        );
      }
    }
    for (final (kind, sec) in [
      ('action', 'actions'),
      ('remote', 'remote'),
      ('value', 'values'),
      ('shared', 'shared'),
    ]) {
      for (final MapEntry(:key, :value) in section(sec).entries) {
        final params = strings(value['params']);
        final valueType = value['value'] == null ? null : '${value['value']}';
        code[Plan.key(kind, key)] = CodeUnit(
          kind,
          key,
          '${value['purpose'] ?? ''}'.trim(),
          params: [
            // A remote action always gets emit (it is how it changes state).
            if (kind == 'remote' && !params.contains('emit')) 'emit',
            ...params.where((x) => x != 'value'),
            if (valueType != null || params.contains('value')) 'value',
          ],
          valueType: valueType,
          returns: '${value['returns'] ?? 'String'}',
          signature: '${value['signature'] ?? ''}',
          uses: strings(value['uses']),
          test: '${value['test'] ?? ''}'.trim(),
          sharedIn: '${value['in'] ?? 'actions'}',
        );
      }
    }
    final tests = <String, Map>{
      for (final MapEntry(:key, :value) in section('tests').entries)
        key: value,
    };
    return Plan(
      appDir,
      '${p['summary'] ?? ''}'.trim(),
      '${p['style'] ?? ''}'.trim(),
      views,
      code,
      tests,
    );
  }

  /// Checks the plan against itself and the contract files: names, cases,
  /// what each unit uses. Errors stop the scaffold; warnings don't.
  ({List<String> errors, List<String> warnings}) lint() {
    final errors = <String>[];
    final warnings = <String>[];
    final pascal = RegExp(r'^[A-Z][a-zA-Z0-9]*$');
    final camel = RegExp(r'^[a-z][a-zA-Z0-9]*$');
    final labels = labelKeys(app);
    final routes = routePages(app);

    for (final v in views.values) {
      if (!pascal.hasMatch(v.name)) errors.add('${v.name}: pages and components are ThisCase');
      if (v.purpose.isEmpty) warnings.add('${v.name}: no purpose');
    }
    for (final c in code.values) {
      if (!camel.hasMatch(c.name)) errors.add('${c.name}: actions, values and helpers are thisCase');
      if (c.purpose.isEmpty) warnings.add('${c.name}: no purpose');
      if (c.kind == 'shared' && c.signature.isEmpty) {
        errors.add('${c.name}: a shared helper needs `signature:` (its Dart declaration)');
      }
      if (c.kind == 'value' && c.params.any((p) => !const {'labels', 'index'}.contains(p))) {
        errors.add('${c.name}: values take only labels and index');
      }
      if (c.kind == 'remote' && c.params.any((p) => !const {'emit', 'value'}.contains(p))) {
        errors.add('${c.name}: remote actions take only emit and value');
      }
      for (final p in c.params) {
        if (!const {'emit', 'core', 'remote', 'labels', 'index', 'value'}.contains(p)) {
          errors.add('${c.name}: unknown param "$p" (emit, core, remote, labels, index, value)');
        }
      }
      if (c.kind == 'action' &&
          ofKind('remote').any((r) => c.uses.contains(r.name)) &&
          !c.params.contains('remote')) {
        errors.add('${c.name}: uses a remote action, so it needs the `remote` param');
      }
    }
    // Names shared by actions, values and labels must be unique (a remote
    // action may share its local action's name).
    final seen = <String, String>{};
    for (final c in code.values.where((c) => c.kind != 'remote')) {
      final prev = seen[c.name];
      if (prev != null) errors.add('${c.name}: both a $prev and a ${c.kind}');
      seen[c.name] = c.kind;
    }
    for (final l in labels) {
      if (seen.containsKey(l)) errors.add('$l: both a label and a ${seen[l]}');
    }

    final known = {
      ...views.keys,
      ...code.values.map((c) => c.name),
      ...labels,
    };
    for (final v in views.values) {
      for (final u in v.uses) {
        if (!known.contains(u)) {
          errors.add('${v.name} uses "$u": not a planned component, value, action, or a label in en.yaml');
        }
        if (views[u]?.page == true) errors.add('${v.name} uses page $u: pages are opened by routes, not embedded');
      }
    }
    for (final c in code.values) {
      for (final u in c.uses) {
        if (!code.values.any((x) => x.name == u && (x.kind == 'shared' || x.kind == 'remote'))) {
          errors.add('${c.name} uses "$u": not a planned shared helper or remote action');
        }
      }
    }
    for (final MapEntry(key: route, value: page) in routes.entries) {
      if (views[page]?.page != true) errors.add('route $route opens $page: not a planned page');
    }
    for (final p in pages) {
      if (!routes.containsValue(p.name) && !(routes.isEmpty && p.name == 'MainPage')) {
        warnings.add('page ${p.name}: no route opens it');
      }
    }
    for (final MapEntry(key: name, value: t) in tests.entries) {
      final route = t['route'];
      if (route != null && !routes.containsKey('$route')) errors.add('test $name: no route "$route"');
    }
    // Everything planned should be reachable.
    final used = {
      for (final v in views.values) ...v.uses,
      for (final c in code.values) ...c.uses,
    };
    Object? start;
    if (File('$app/app.yaml').existsSync()) {
      final y = loadYaml(File('$app/app.yaml').readAsStringSync());
      if (y is YamlMap) start = y['start'];
    }
    if (start != null) used.add('$start');
    for (final c in code.values) {
      if (c.kind != 'remote' && !used.contains(c.name)) {
        warnings.add('${c.kind} ${c.name}: nothing in the plan uses it');
      }
    }
    for (final v in components) {
      if (!used.contains(v.name)) warnings.add('component ${v.name}: nothing in the plan uses it');
    }
    return (errors: errors, warnings: warnings);
  }
}

class PlanError implements Exception {
  final String message;
  PlanError(this.message);
  @override
  String toString() => message;
}

/// Label keys in en.yaml.
Set<String> labelKeys(String appDir) {
  final f = File('$appDir/app/views/labels/en.yaml');
  if (!f.existsSync()) return {};
  final y = loadYaml(f.readAsStringSync());
  final en = y is YamlMap ? y['en'] : null;
  return en is YamlMap ? {for (final k in en.keys) '$k'} : {};
}

/// Routes in navigation.yaml: route -> page.
Map<String, String> routePages(String appDir) {
  final f = File('$appDir/app/views/navigation.yaml');
  if (!f.existsSync()) return {};
  final y = loadYaml(f.readAsStringSync());
  final routes = y is YamlMap ? y['routes'] : null;
  if (routes is! YamlMap) return {};
  return {
    for (final e in routes.entries)
      '${e.key}': e.value is YamlMap
          ? '${(e.value as YamlMap).values.first}'
          : '${e.value}',
  };
}

/// Route kinds: route -> page | bottomSheet | dialog.
Map<String, String> routeKinds(String appDir) {
  final f = File('$appDir/app/views/navigation.yaml');
  if (!f.existsSync()) return {};
  final y = loadYaml(f.readAsStringSync());
  final routes = y is YamlMap ? y['routes'] : null;
  if (routes is! YamlMap) return {};
  return {
    for (final e in routes.entries)
      '${e.key}': e.value is YamlMap ? '${(e.value as YamlMap).keys.first}' : 'page',
  };
}

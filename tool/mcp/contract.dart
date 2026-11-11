// The contract from the plan: when plan.yaml holds `models:`, `state:`,
// `labels:` and `routes:` (and `start:`), the scaffold writes app.yaml,
// app/models/*.yaml, app/models/state.yaml, app/views/labels/en.yaml and
// app/views/navigation.yaml from them, so the planner writes one file and
// says each field's type and initial value once.
//
//   models:
//     category: [transport, stay]                 # enum
//     item: {title: string, cost: number}         # model
//     trip: {purpose: a planned trip, fields: {name: string, items: list(item)}}
//   state:
//     ephemeral: {draft: string = '', status: rateStatus = idle}
//     local:
//       selected: number = 0
//       trips: {type: list(trip), initial: [{name: Lisbon, items: []}]}
//   labels: {appTitle: Trips}
//   routes: {home: MainPage, addItem: {bottomSheet: AddItemSheet}}   # the first opens first
//   start: loadRate

import 'dart:convert';
import 'dart:io';

import 'package:metacode/compiler/issues.dart' show snakeCase;
import 'package:yaml/yaml.dart';


const _generated = '(Written from plan.yaml by the scaffold: change the plan, then scaffold again.)';

/// Writes the contract files the plan defines; returns them. Errors (a bad
/// state field) are added to [errors] and nothing is written.
List<String> writeContract(String app, YamlMap p, List<String> errors) {
  final written = <String>[];
  final out = <String, String>{};
  final name = '${p['name'] ?? app.split('/').last}';
  final summary = '${p['summary'] ?? ''}'.trim();

  // Models.
  final models = p['models'];
  final enums = <String, String>{}; // enum -> first value
  if (models is YamlMap) {
    for (final MapEntry(key: k, value: v) in models.entries) {
      final model = '$k';
      String? purpose;
      Object? body = v;
      if (v is YamlMap && v.containsKey('fields') && v.keys.every((x) => x == 'fields' || x == 'purpose')) {
        purpose = v['purpose']?.toString();
        body = v['fields'];
      } else if (v is YamlMap && v.containsKey('values') && v.keys.every((x) => x == 'values' || x == 'purpose')) {
        purpose = v['purpose']?.toString();
        body = v['values'];
      }
      if (body is YamlList && body.isNotEmpty) enums[model] = '${body.first}';
      out['app/models/${snakeCase(model)}.yaml'] =
          '# $model: ${purpose ?? (body is YamlList ? 'one of ${body.join(', ')}' : 'a model')}.\n# $_generated\n'
          '$model:${_yaml(_plain(body), '  ')}\n';
    }
  }

  // State: types to state.yaml, initial values to app.yaml.
  final state = p['state'];
  if (state is YamlMap) {
    const scopes = {'ephemeral', 'local', 'remote', 'system', 'shared'};
    final scoped = state.keys.every((k) => scopes.contains('$k'));
    final groups = scoped ? state : YamlMap.wrap({'local': state});
    final types = <String, Map<String, Object?>>{};
    final initial = <String, Map<String, Object?>>{};
    for (final MapEntry(key: scope, value: fields) in groups.entries) {
      if (fields is! YamlMap) {
        errors.add('plan.state.$scope must be a map of field: type = initial');
        continue;
      }
      final t = types['$scope'] = {};
      final i = initial['$scope'] = {};
      for (final MapEntry(key: f, value: def) in fields.entries) {
        String type;
        Object? init;
        var hasInit = false;
        if (def is YamlMap && def.containsKey('type')) {
          type = '${def['type']}';
          hasInit = def.containsKey('initial');
          init = _plain(def['initial']);
        } else {
          final text = '$def';
          final at = text.indexOf(' = ');
          type = (at < 0 ? text : text.substring(0, at)).trim();
          if (at >= 0) {
            hasInit = true;
            init = _plain(loadYaml(text.substring(at + 3)));
          }
        }
        if (!hasInit) {
          init = _default(type, enums);
          if (init == _none) {
            errors.add('plan.state.$scope.$f: give `$type` an initial value '
                '(`$f: $type = ...`, or {type: $type, initial: ...})');
            continue;
          }
        }
        t['$f'] = type;
        i['$f'] = init;
      }
    }
    out['app/models/state.yaml'] = '# state: the app\'s state, by scope (initial values in app.yaml).\n# $_generated\n'
        'state:${_yaml(types, '  ')}\n';
    final start = p['start'];
    out['app.yaml'] = '# $name: ${_oneLine(summary)}\n# Types in app/models/state.yaml. $_generated\n'
        'name: $name\n'
        'description: ${jsonEncode(_oneLine(summary))}\n'
        '${start == null ? '' : 'start: $start\n'}'
        'state:${_yaml(initial, '  ')}\n';
  }

  // Labels: the plan's, plus any an agent added (add_labels) since.
  final labels = p['labels'];
  if (labels is YamlMap) {
    final file = File('$app/app/views/labels/en.yaml');
    final kept = <String, Object?>{};
    if (file.existsSync()) {
      final y = loadYaml(file.readAsStringSync());
      final en = y is YamlMap ? y['en'] : null;
      if (en is YamlMap) {
        for (final e in en.entries) {
          if (!labels.containsKey(e.key)) kept['${e.key}'] = e.value;
        }
      }
    }
    out['app/views/labels/en.yaml'] = '# en: every text the app shows, in English.\n# $_generated\n'
        'en:${_yaml({...?_plain(labels) as Map?, ...kept}, '  ')}\n';
  }

  // Routes: the first one opens first.
  final routes = p['routes'];
  if (routes is YamlMap && routes.isNotEmpty) {
    out['app/views/navigation.yaml'] = '# navigation: the routes; ${routes.keys.first} opens first.\n# $_generated\n'
        'initial: ${routes.keys.first}\n'
        'routes:${_yaml(_plain(routes), '  ')}\n';
  }

  if (errors.isNotEmpty) return written;
  for (final MapEntry(key: rel, value: text) in out.entries) {
    final f = File('$app/$rel');
    if (f.existsSync() && f.readAsStringSync() == text) continue;
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(text);
    written.add(rel);
  }
  return written;
}

const _none = Object();

Object? _default(String type, Map<String, String> enums) {
  if (type.endsWith('?')) return null;
  if (type.startsWith('list(')) return <Object?>[];
  switch (type) {
    case 'string':
      return '';
    case 'number':
      return 0;
    case 'boolean':
      return false;
  }
  return enums[type] ?? _none;
}

String _oneLine(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

Object? _plain(Object? v) => v is Map
    ? {for (final e in v.entries) '${e.key}': _plain(e.value)}
    : v is List
        ? [for (final x in v) _plain(x)]
        : v;

/// Block YAML for maps (one key per line), flow style for lists of scalars
/// and short maps inside lists; scalars quoted only when YAML would misread
/// them. Starts with a newline (or a space for an inline value).
String _yaml(Object? v, String indent) {
  if (v is Map) {
    if (v.isEmpty) return ' {}';
    return [
      for (final e in v.entries) '\n$indent${_key(e.key)}:${_yaml(e.value, '$indent  ')}',
    ].join();
  }
  if (v is List) {
    if (v.isEmpty) return ' []';
    if (v.every((x) => x is! Map && x is! List)) return ' [${v.map(_scalar).join(', ')}]';
    return [for (final x in v) '\n${indent.substring(2)}- ${_flow(x)}'].join();
  }
  return ' ${_scalar(v)}';
}

/// One line: a list item that is a map or list.
String _flow(Object? v) {
  if (v is Map) return '{${v.entries.map((e) => '${_key(e.key)}: ${_flow(e.value)}').join(', ')}}';
  if (v is List) return '[${v.map(_flow).join(', ')}]';
  return _scalar(v);
}

String _key(Object? k) => RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch('$k') ? '$k' : jsonEncode('$k');

String _scalar(Object? v) {
  if (v == null) return 'null';
  if (v is num || v is bool) return '$v';
  final s = '$v';
  final plain = RegExp(r'^[A-Za-z][A-Za-z0-9 _.()-]*$').hasMatch(s) &&
      !RegExp(r'^(true|false|null|yes|no|on|off|y|n|~)$', caseSensitive: false).hasMatch(s) &&
      !s.endsWith(' ');
  return plain ? s : jsonEncode(s);
}

/// The plan's YAML root (for the contract sections).
YamlMap? planRoot(String app) {
  final f = File('$app/plan.yaml');
  if (!f.existsSync()) return null;
  try {
    final y = loadYaml(f.readAsStringSync());
    return y is YamlMap && y['plan'] is YamlMap ? y['plan'] as YamlMap : null;
  } on YamlException {
    return null;
  }
}

/// Whether the plan carries the contract (then the scaffold writes it).
bool hasContract(YamlMap p) => ['models', 'state', 'labels', 'routes'].any(p.containsKey);

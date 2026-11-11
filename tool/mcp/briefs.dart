// Briefs: the plan cut into self-contained work orders, one per agent.
// Each brief holds everything its agent needs (its files' contracts, the
// app's types, labels, the names it may use, the reference sections that
// apply), so the agent writes and validates without exploring the app.

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'plan.dart';
import 'scaffold.dart';

class Brief {
  final String role; // designer | coder | stylist
  final List<String> files;
  final String prompt;
  Brief(this.role, this.files, this.prompt);
  Map<String, Object> toJson() => {
    'role': role,
    'files': files,
    'prompt': prompt,
  };
}

/// [perAgent]: how many units each designer/coder brief holds at most.
/// [pending]: only units whose file is still a stub (a re-run after some
/// agents finished).
List<Brief> briefs(Plan plan, {int perAgent = 30, bool pending = true}) {
  bool todo(String file) =>
      !pending ||
      isStub('${plan.app}/$file') ||
      !File('${plan.app}/$file').existsSync();
  final out = <Brief>[];

  // Code: each local action with its remote twin; shared helpers with their
  // first user, so the helper and the code relying on it come from one hand.
  final placed = <String>{};
  final groups = <List<CodeUnit>>[];
  for (final c in plan.code.values.where(
    (c) => c.kind == 'action' || c.kind == 'value',
  )) {
    final g = <CodeUnit>[c];
    placed.add(Plan.key(c.kind, c.name));
    for (final u in c.uses) {
      for (final k in [Plan.key('shared', u), Plan.key('remote', u)]) {
        final d = plan.code[k];
        if (d != null && placed.add(k)) g.add(d);
      }
    }
    final twin = plan.code[Plan.key('remote', c.name)];
    if (twin != null && placed.add(Plan.key('remote', c.name))) g.add(twin);
    groups.add(g);
  }
  for (final MapEntry(:key, :value) in plan.code.entries) {
    if (placed.add(key)) groups.add([value]);
  }
  final codeChunks = _chunk(
    [
      for (final g in groups)
        [
          for (final c in g)
            if (todo(c.file)) c,
        ],
    ]..removeWhere((g) => g.isEmpty),
    perAgent,
  );
  for (final chunk in codeChunks) {
    out.add(
      Brief('coder', [
        for (final c in chunk) c.file,
      ], _coderPrompt(plan, chunk)),
    );
  }

  // Views: each page with the components only it reaches.
  final owner = <String, String>{};
  final viewGroups = <List<ViewUnit>>[];
  for (final p in plan.pages) {
    final g = <ViewUnit>[p];
    final queue = [...p.uses];
    while (queue.isNotEmpty) {
      final n = queue.removeAt(0);
      final v = plan.views[n];
      if (v == null || v.page || owner.containsKey(n)) continue;
      owner[n] = p.name;
      g.add(v);
      queue.addAll(v.uses);
    }
    viewGroups.add(g);
  }
  for (final v in plan.components.where((v) => !owner.containsKey(v.name))) {
    viewGroups.add([v]);
  }
  // Page groups packed together (a group is split only when it alone is
  // bigger than perAgent), so a small app gets one designer.
  final viewChunks = _chunk(
    [
      for (final g in viewGroups)
        [
          for (final v in g)
            if (todo(v.file)) v,
        ],
    ]..removeWhere((g) => g.isEmpty),
    perAgent,
  );
  for (final chunk in viewChunks) {
    out.add(
      Brief('designer', [
        for (final v in chunk) v.file,
      ], _designerPrompt(plan, chunk)),
    );
  }

  // The style rides with the smallest designer brief (no agent of its own).
  if (plan.style.isNotEmpty &&
      !Directory('${plan.app}/app/views/style').existsSync()) {
    final designers = out.where((b) => b.role == 'designer').toList()
      ..sort((a, b) => a.files.length - b.files.length);
    if (designers.isEmpty) {
      out.add(Brief('stylist', ['app/views/style/'], _stylistPrompt(plan)));
    } else {
      final d = designers.first;
      out[out.indexOf(d)] = Brief(
        'designer',
        [...d.files, 'app/views/style/'],
        '${d.prompt}\n\n---\n\nALSO, as the stylist:\n\n${_stylistPrompt(plan)}',
      );
    }
  }
  return out;
}

/// Packs groups into chunks of at most [n] units (a group is never split
/// unless it alone is bigger).
List<List<T>> _chunk<T>(List<List<T>> groups, int n) {
  final out = <List<T>>[];
  var cur = <T>[];
  for (final whole in groups) {
    final parts = [
      for (var i = 0; i < whole.length; i += n)
        whole.sublist(i, (i + n).clamp(0, whole.length)),
    ];
    for (final g in parts) {
      if (cur.isNotEmpty && cur.length + g.length > n) {
        out.add(cur);
        cur = [];
      }
      cur.addAll(g);
    }
  }
  if (cur.isNotEmpty) out.add(cur);
  return out;
}

// ---------------------------------------------------------------------------

String _read(String path) {
  final f = File(path);
  return f.existsSync() ? f.readAsStringSync() : '';
}

/// A `## heading` section of a markdown file.
String _section(String path, String heading) {
  final text = _read(path);
  final start = text.indexOf('\n## $heading');
  if (start < 0) return '';
  final end = text.indexOf('\n## ', start + 4);
  return text.substring(start + 1, end < 0 ? text.length : end).trim();
}

const _ref = '.claude/skills/metacode-app/REFERENCE.md';
const _style = '.claude/skills/metacode-app/reference/style.md';

String _noComments(String yaml) => yaml
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('#') && l.trim().isNotEmpty)
    .join('\n');

/// The app's types: state.yaml and every model, comments stripped.
String _types(Plan plan) {
  final dir = Directory('${plan.app}/app/models');
  if (!dir.existsSync()) return '';
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files.map((f) => _noComments(f.readAsStringSync())).join('\n');
}

String _initialState(Plan plan) {
  final y = loadYaml(_read('${plan.app}/app.yaml'));
  final s = y is YamlMap ? y['state'] : null;
  if (s == null) return '';
  final text = _read('${plan.app}/app.yaml');
  final i = text.indexOf('\nstate:');
  return i < 0 ? '' : _noComments(text.substring(i + 1));
}

String _labels(Plan plan) =>
    _noComments(_read('${plan.app}/app/views/labels/en.yaml'));

String _routes(Plan plan) =>
    _noComments(_read('${plan.app}/app/views/navigation.yaml'));

String _sig(CodeUnit c) => switch (c.kind) {
  'value' => '${c.name}(${['state', ...c.params].join(', ')}) -> ${c.returns}',
  'remote' => 'remote.${c.name}(${c.valueType ?? ''})',
  'shared' => c.signature,
  _ =>
    '${c.name}(${['state', ...c.params.map((p) => p == 'value' ? 'value: ${c.valueType ?? 'String'}' : p)].join(', ')})',
};

String _header(Plan plan, String role) =>
    '''
You are a Metacode $role. App: `${plan.app}/` (paths below are relative to it).
${plan.summary}
''';

String _coderPrompt(Plan plan, List<CodeUnit> units) {
  final b = StringBuffer(_header(plan, 'coder'))
    ..writeln(
      '\n## Your files (stubs exist: fill them, keep each header comment true, remove the `$stubMarker` line)\n',
    );
  for (final c in units) {
    b.writeln('- `${c.file}`: **${c.declaration.replaceAll(' async', '')}**');
    b.writeln('  ${c.purpose}');
    if (c.test.isNotEmpty) b.writeln('  Test: ${c.test}');
    if (c.uses.isNotEmpty) b.writeln('  Calls: ${c.uses.join(', ')}');
    final by = plan.usedBy(c.name);
    if (by.isNotEmpty) b.writeln('  Used by: ${by.join(', ')}');
  }
  final others = plan.code.values
      .where(
        (c) => !units.contains(c) && (c.kind == 'shared' || c.kind == 'remote'),
      )
      .toList();
  if (others.isNotEmpty) {
    b.writeln(
      '\n## Helpers and remote actions written by other agents (call them, never edit them)\n',
    );
    for (final c in others) {
      b.writeln('- ${_sig(c)} (`${c.file}`): ${c.purpose}');
    }
  }
  b
    ..writeln(
      '\n## Types (app/models/): Dart classes are the names capitalized (`trip` -> `Trip`), enums too\n',
    )
    ..writeln('```yaml\n${_types(plan)}\n```')
    ..writeln('\n## Initial state (app.yaml), what `sample()` returns\n')
    ..writeln('```yaml\n${_initialState(plan)}\n```')
    ..writeln('\n## Labels (labels.<key> when you take `labels`)\n')
    ..writeln('```yaml\n${_labels(plan)}\n```');
  final routes = _routes(plan);
  if (routes.isNotEmpty) {
    b.writeln(
      '\n## Routes (`core.navigator.push(Routes.<name>)`)\n\n```yaml\n$routes\n```',
    );
  }
  b.writeln('\n${_section(_ref, 'dart_eval limitations')}');
  if (units.any((c) => c.params.contains('core'))) {
    b.writeln('\n${_section(_ref, 'Core: api, navigator and locale')}');
  }
  b.writeln(
    '\nWhen done, reply with one line per file: its path and OK, or what is left.',
  );
  return b.toString();
}

String _designerPrompt(Plan plan, List<ViewUnit> units) {
  final b = StringBuffer(_header(plan, 'designer'))
    ..writeln(
      '\n## Your files (stubs exist: replace each body, keep the header comment true, remove the `$stubMarker` line)\n',
    );
  for (final v in units) {
    b.writeln(
      '- `${v.file}`: **${v.name}**${v.params.isEmpty ? '' : ' (params: ${v.params.entries.map((e) => '.${e.key}: ${e.value}').join(', ')})'}',
    );
    b.writeln('  ${v.purpose}');
    if (v.uses.isNotEmpty) b.writeln('  Uses: ${v.uses.join(', ')}');
    final by = plan.usedBy(v.name);
    if (by.isNotEmpty) b.writeln('  Used by: ${by.join(', ')}');
  }
  b.writeln(
    '\n## What you can reference (others write these; use them by name, never edit them)\n',
  );
  final comps = plan.components.where((v) => !units.contains(v)).toList();
  if (comps.isNotEmpty) {
    b.writeln('Components:');
    for (final v in comps) {
      b.writeln(
        '- ${v.name}${v.params.isEmpty ? '' : '{${v.params.keys.join(', ')}}'}: ${v.purpose}',
      );
    }
  }
  b.writeln(
    '\nValues (the result type decides the prop: List -> listView/gridView `data`, bool -> `if` condition, String -> text or a color name):',
  );
  for (final c in plan.ofKind('value')) {
    b.writeln('- ${_sig(c)}: ${c.purpose}');
  }
  b.writeln(
    '\nActions (`index` comes from the list item or the component\'s `index:`; `value` from the input that runs it):',
  );
  for (final c in plan.ofKind('action')) {
    b.writeln('- ${_sig(c)}: ${c.purpose}');
  }
  b
    ..writeln('\nLabels (app/views/labels/en.yaml; reference by key):')
    ..writeln('```yaml\n${_labels(plan)}\n```');
  final routes = _routes(plan);
  if (routes.isNotEmpty) b.writeln('\nRoutes:\n```yaml\n$routes\n```');
  b
    ..writeln('\n${_section(_ref, 'app/views/')}')
    ..writeln('\n${_section(_ref, 'Widgets')}')
    ..writeln('\n${_section(_style, 'Icons')}')
    ..writeln('\n${_section(_style, 'Colors')}')
    ..writeln('\n${_section(_style, 'Text variants')}')
    ..writeln(
      '\nWhen done, reply with one line per file: its path and OK, or what is left.',
    );
  return b.toString();
}

String _stylistPrompt(Plan plan) {
  final b = StringBuffer(_header(plan, 'stylist'))
    ..writeln('\n## Your job\n')
    ..writeln(
      'Write the design tokens in `app/views/style/` (one group per file, each file one top-level key named after it, a header comment): ${plan.style}',
    )
    ..writeln(
      'Write `colors.yaml` (light and dark, every token in the table below), `fonts.yaml`, `radius.yaml`, and `theme.yaml` only if it differs from system. Keys left out fall back to the Metacode style. Touch nothing else.\n',
    )
    ..writeln(
      _read(
            _style,
          ).split('\n## Style').skip(1).join('\n## Style').trim().isEmpty
          ? ''
          : '## Style${_read(_style).split('\n## Style').skip(1).join('\n## Style')}',
    )
    ..writeln('\nWhen done, reply with one line: the files written.');
  return b.toString();
}

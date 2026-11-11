// Metacode agent tools: an MCP server (stdio) and the same tools as a CLI.
//
//   tool/mc serve                         MCP server over stdio (.mcp.json)
//   tool/mc <tool> <app> [--arg value]    one tool from the shell, e.g.
//   tool/mc validate examples/travel --files app/actions/a.dart,app/views/pages/main_page.yaml
//
// Tools: init, scaffold, briefs, brief, validate, test, layout, add_labels, check, status.
// The flow they serve (plan -> scaffold -> parallel agents -> check) is in
// .claude/skills/metacode-new-app/SKILL.md.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'mcp/briefs.dart';
import 'mcp/checks.dart';
import 'mcp/contract.dart';
import 'mcp/plan.dart';
import 'mcp/scaffold.dart';

typedef Handler = Future<String> Function(Map<String, dynamic> args);

class Tool {
  final String name;
  final String description;
  final Map<String, Object> properties;
  final List<String> required;
  final Handler run;
  Tool(this.name, this.description, this.properties, this.required, this.run);

  Map<String, Object> get schema => {
        'name': name,
        'description': description,
        'inputSchema': {
          'type': 'object',
          'properties': properties,
          'required': required,
        },
      };
}

const _app = {
  'type': 'string',
  'description': 'The app folder, relative to the repo root (examples/travel).',
};

final tools = <Tool>[
  Tool(
    'init',
    'Creates a new app folder with a plan.yaml template: the one file to '
        'write (format: .claude/skills/metacode-new-app/PLAN.md); scaffold '
        'writes everything else from it. Never overwrites. Step 1 of a new app.',
    {
      'app': _app,
      'name': {'type': 'string', 'description': 'The app name (thisCase).'},
      'description': {'type': 'string'},
    },
    ['app', 'name'],
    (a) async => _init('${a['app']}', '${a['name']}', '${a['description'] ?? ''}'),
  ),
  Tool(
    'scaffold',
    'Writes the contract from plan.yaml when it has models/state/labels/'
        'routes (app.yaml, app/models/, labels, navigation), lints the plan '
        'against it, then writes a compiling '
        'stub for every planned page, component, action, remote action, '
        'value and helper (header, signature, imports, test skeleton), '
        'app/models/sample.dart and tests/*.yaml, and validates the app. '
        'Existing non-stub files are kept. Fix every error it reports before '
        'handing out briefs.',
    {'app': _app},
    ['app'],
    (a) async {
      final app = '${a['app']}';
      // The contract first (when the plan carries it): the lint reads labels
      // and routes from the files it writes.
      final root = planRoot(app);
      final contractErrors = <String>[];
      final contract = root != null && hasContract(root) ? writeContract(app, root, contractErrors) : <String>[];
      if (contractErrors.isNotEmpty) {
        return 'PLAN ERRORS (nothing written):\n${contractErrors.map((e) => '- $e').join('\n')}';
      }
      final plan = Plan.load(app);
      final lint = plan.lint();
      final out = StringBuffer();
      if (contract.isNotEmpty) out.writeln('Contract from the plan: ${contract.join(', ')}');
      if (lint.errors.isNotEmpty) {
        return 'PLAN ERRORS (nothing written):\n${lint.errors.map((e) => '- $e').join('\n')}'
            '${lint.warnings.isEmpty ? '' : '\nwarnings:\n${lint.warnings.map((e) => '- $e').join('\n')}'}';
      }
      final written = scaffold(plan);
      out.writeln('Wrote ${written.length} stub(s): ${plan.views.length} views, '
          '${plan.code.length} code units, ${plan.tests.length} test states.');
      for (final w in lint.warnings) {
        out.writeln('warning: $w');
      }
      out.write(await validate('${a['app']}'));
      return out.toString();
    },
  ),
  Tool(
    'briefs',
    'Cuts the plan into self-contained work orders (designer, coder, '
        'stylist), one per agent, for the units still stubs. Writes each to '
        '<app>/.plan/briefs/<id>.md and returns the list: spawn one agent per '
        'brief, in parallel, with a prompt naming its brief file.',
    {
      'app': _app,
      'per_agent': {
        'type': 'integer',
        'description': 'Most units per brief (default 30: each agent costs a fixed ~30k tokens to start, so fewer, fuller agents are cheaper; briefs of 30-40 units finish in ~2 minutes).',
      },
    },
    ['app'],
    (a) async {
      final app = '${a['app']}';
      final plan = Plan.load(app);
      final per = int.tryParse('${a['per_agent'] ?? ''}') ?? 30;
      final list = briefs(plan, perAgent: per);
      final dir = Directory('$app/.plan/briefs');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      final out = StringBuffer('${list.length} brief(s):\n');
      for (final (i, b) in list.indexed) {
        final id = '${(i + 1).toString().padLeft(2, '0')}-${b.role}';
        File('${dir.path}/$id.md').writeAsStringSync(b.prompt);
        out.writeln('- $app/.plan/briefs/$id.md (${b.role}, ${b.prompt.length ~/ 1000}k chars): ${b.files.join(', ')}');
      }
      return out.toString().trim();
    },
  ),
  Tool(
    'brief',
    'Returns one brief written by `briefs`: what an agent must do.',
    {
      'path': {'type': 'string', 'description': 'The brief file (<app>/.plan/briefs/<id>.md).'},
    },
    ['path'],
    (a) async => File('${a['path']}').readAsStringSync(),
  ),
  Tool(
    'validate',
    'Fast check of some files (~1s): builds the whole app in memory (every '
        'YAML and signature rule, the dart_eval compile) and type-checks the '
        'given .dart files; reports only errors in `files` (others are '
        'counted). Safe to call from many agents. Does not run tests.',
    {
      'app': _app,
      'files': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Paths relative to the app (app/actions/x.dart). Empty: the whole app.',
      },
    },
    ['app'],
    (a) async => validate('${a['app']}', only: _list(a['files'])),
  ),
  Tool(
    'add_labels',
    'Adds labels (key: English text) to every labels file of the app, '
        'atomically (agents must not edit en.yaml themselves). Keys that '
        'exist are left as they are.',
    {
      'app': _app,
      'labels': {
        'type': 'object',
        'additionalProperties': {'type': 'string'},
        'description': '{"tripCount": "trips"}',
      },
    },
    ['app', 'labels'],
    (a) async => _addLabels('${a['app']}', (a['labels'] as Map).cast<String, Object?>()),
  ),
  Tool(
    'check',
    'The full check (~15s): generates, runs every test (the main() in each '
        'action and value) and the layout check (every route at phone, '
        'tablet and desktop, and tests/*.yaml states). Failures grouped by '
        'file. Run it once all agents are done, not from the agents.',
    {'app': _app},
    ['app'],
    (a) async => check('${a['app']}'),
  ),
  Tool(
    'test',
    'Runs the tests of some files only (the main() of each action and '
        'value given), through the interpreter like the app, ~5-10s. For '
        'agents, after validate: catches interpreter crashes and wrong '
        'results in their own files. Calls run one at a time.',
    {
      'app': _app,
      'files': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Action and value files, relative to the app.',
      },
    },
    ['app', 'files'],
    (a) async => check('${a['app']}', only: _list(a['files'])),
  ),
  Tool(
    'layout',
    'Renders every route and tests/*.yaml state at 360, 390, 820 and 1440 '
        'wide and reports overflows and render errors (~10-20s). For '
        'designers, after validate: fix the failures in your own files. '
        'Values still being written return placeholders, so text lengths '
        'are not final: aim for layouts that never overflow (expanded, '
        'maxLines, wrap).',
    {'app': _app},
    ['app'],
    (a) async => check('${a['app']}', layoutOnly: true),
  ),
  Tool(
    'status',
    'Progress: plan lint, and which planned files are still stubs.',
    {'app': _app},
    ['app'],
    (a) async {
      final plan = Plan.load('${a['app']}');
      final lint = plan.lint();
      final files = [
        for (final v in plan.views.values) v.file,
        for (final c in plan.code.values) c.file,
      ];
      final stubs = files.where((f) => isStub('${a['app']}/$f')).toList();
      return '${files.length - stubs.length}/${files.length} planned files done.'
          '${stubs.isEmpty ? '' : '\nstubs: ${stubs.join(', ')}'}'
          '${lint.errors.isEmpty ? '' : '\nplan errors:\n${lint.errors.map((e) => '- $e').join('\n')}'}';
    },
  ),
];

List<String> _list(Object? v) => v == null
    ? const []
    : v is List
        ? [for (final x in v) '$x']
        : '$v'.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

// --- init -------------------------------------------------------------------

String _init(String app, String name, String description) {
  final made = <String>[];
  void put(String rel, String contents) {
    final f = File('$app/$rel');
    if (f.existsSync()) return;
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(contents);
    made.add(rel);
  }

  put('plan.yaml', File('.claude/skills/metacode-new-app/plan_template.yaml').existsSync()
      ? File('.claude/skills/metacode-new-app/plan_template.yaml').readAsStringSync()
      : 'plan:\n  summary: $description\n  pages:\n    MainPage: {purpose: the first screen}\n');
  if (made.isNotEmpty) {
    final f = File('$app/plan.yaml');
    f.writeAsStringSync(f.readAsStringSync().replaceFirst('TODO one paragraph, what the app is for and how it feels.', description.isEmpty ? 'TODO' : description));
  }
  return made.isEmpty ? 'Nothing written: $app exists.' : 'Created in $app: ${made.join(', ')}';
}

// --- labels -----------------------------------------------------------------

String _addLabels(String app, Map<String, Object?> labels) {
  final dir = Directory('$app/app/views/labels');
  if (!dir.existsSync()) return 'no labels folder in $app';
  final added = <String>{};
  for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml'))) {
    final text = f.readAsStringSync();
    final keys = RegExp(r'^  ([a-zA-Z0-9]+):', multiLine: true).allMatches(text).map((m) => m[1]).toSet();
    final buf = StringBuffer(text.endsWith('\n') ? text : '$text\n');
    for (final MapEntry(:key, :value) in labels.entries) {
      if (keys.contains(key)) continue;
      buf.writeln('  $key: ${jsonEncode('$value')}');
      added.add(key);
    }
    f.writeAsStringSync(buf.toString());
  }
  final kept = labels.keys.where((k) => !added.contains(k));
  return 'added: ${added.isEmpty ? 'none' : added.join(', ')}'
      '${kept.isEmpty ? '' : '; already there: ${kept.join(', ')}'}';
}

// --- entry ------------------------------------------------------------------

Future<void> main(List<String> args) async {
  _toRepoRoot();
  if (args.isEmpty || args.first == 'serve') return _serve();
  final tool = tools.where((t) => t.name == args.first).firstOrNull;
  if (tool == null) {
    stderr.writeln('tools: ${tools.map((t) => t.name).join(', ')}, serve');
    exit(64);
  }
  final a = <String, dynamic>{};
  final rest = args.skip(1).toList();
  if (rest.isNotEmpty && !rest.first.startsWith('--')) {
    a[tool.required.first] = rest.removeAt(0);
  }
  for (var i = 0; i + 1 < rest.length; i += 2) {
    final key = rest[i].replaceFirst('--', '');
    final v = rest[i + 1];
    a[key] = key == 'labels' ? jsonDecode(v) : v;
  }
  try {
    final out = await tool.run(a);
    stdout.writeln(out);
    if (out.startsWith('FAIL') || out.startsWith('PLAN ERRORS') || RegExp(r'^\d+ error').hasMatch(out)) {
      exitCode = 1;
    }
  } on PlanError catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  }
}

/// Tools take paths relative to the repo root; the server may start
/// anywhere inside it.
void _toRepoRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/tool/mcp.dart').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) return;
    dir = parent;
  }
  Directory.current = dir;
}

/// MCP over stdio: newline-delimited JSON-RPC 2.0. Requests are handled one
/// at a time, so tools never race on the app's files.
Future<void> _serve() async {
  void send(Map<String, Object?> m) => stdout.writeln(jsonEncode({'jsonrpc': '2.0', ...m}));
  final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    if (line.trim().isEmpty) continue;
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(line) as Map<String, dynamic>;
    } on FormatException {
      send({'id': null, 'error': {'code': -32700, 'message': 'parse error'}});
      continue;
    }
    final id = msg['id'];
    final method = msg['method'];
    if (id == null) continue; // notifications (initialized, cancelled)
    switch (method) {
      case 'initialize':
        final params = (msg['params'] as Map?) ?? {};
        send({
          'id': id,
          'result': {
            'protocolVersion': params['protocolVersion'] ?? '2025-06-18',
            'capabilities': {'tools': {}},
            'serverInfo': {'name': 'metacode', 'version': '0.1.0'},
            'instructions': 'Builds Metacode apps from a plan: init -> write the '
                'contract files and plan.yaml -> scaffold -> briefs (one agent '
                'per brief, in parallel, each using validate) -> check. See '
                '.claude/skills/metacode-new-app/SKILL.md.',
          },
        });
      case 'ping':
        send({'id': id, 'result': {}});
      case 'tools/list':
        send({'id': id, 'result': {'tools': [for (final t in tools) t.schema]}});
      case 'tools/call':
        final params = msg['params'] as Map;
        final tool = tools.where((t) => t.name == params['name']).firstOrNull;
        if (tool == null) {
          send({'id': id, 'error': {'code': -32602, 'message': 'unknown tool ${params['name']}'}});
          break;
        }
        String text;
        var isError = false;
        try {
          text = await tool.run(((params['arguments'] as Map?) ?? {}).cast<String, dynamic>());
          isError = text.startsWith('FAIL') || text.startsWith('PLAN ERRORS');
        } catch (e, s) {
          text = e is PlanError ? '$e' : '$e\n${s.toString().split('\n').take(6).join('\n')}';
          isError = true;
        }
        send({
          'id': id,
          'result': {
            'content': [
              {'type': 'text', 'text': text},
            ],
            'isError': isError,
          },
        });
      default:
        send({'id': id, 'error': {'code': -32601, 'message': 'no method $method'}});
    }
  }
}

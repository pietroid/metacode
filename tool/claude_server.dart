// The Claude bridge: a thin HTTP server between the editor module and a
// headless Claude Code (`claude -p`) that edits a Metacode project with the
// metacode MCP tools (.mcp.json). One request is one whole run, awaited:
//
//   POST /claude  {prompt: String, project: metacodeProject}
//   200           {ok, project, reply, costUsd, durationMs, turns}
//   GET /starter  the editor's starter draft (state.remote.draft in
//                 examples/my_own_app/modules/editor/app.yaml), for its reset
//   GET /project?name=food  one of the root app's modules (food, travel,
//                 work) as a project, its sources only, for the editor to load
//
// The project is written to build/claude_drafts/<id>/ (an app folder in the
// repo, so the MCP tools take it as `build/claude_drafts/<id>`), Claude runs
// from the repo root (CLAUDE.md, skills, .mcp.json), and the folder is read
// back as the new project (sources only: .generated/ and .state/ dropped).
//
//   dart run tool/claude_server.dart            # :8787
//   PORT=9000 CLAUDE_MODEL=sonnet dart run tool/claude_server.dart
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package:metacode/files/metacode_project.dart';

final _root = File.fromUri(Platform.script).parent.parent.path;

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8787;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('claude bridge: http://localhost:$port/claude');
  await for (final request in server) {
    _handle(request);
  }
}

Future<void> _handle(HttpRequest request) async {
  final response = request.response;
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'content-type');
  if (request.method == 'OPTIONS') {
    await response.close();
    return;
  }
  if (request.method == 'GET' && request.uri.path == '/starter') {
    final yaml = loadYaml(File(
            '$_root/examples/my_own_app/modules/editor/app.yaml')
        .readAsStringSync()) as Map;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(yaml['state']['remote']['draft']));
    await response.close();
    return;
  }
  if (request.method == 'GET' && request.uri.path == '/project') {
    final name = request.uri.queryParameters['name'] ?? '';
    final dir = Directory('$_root/examples/my_own_app/modules/$name');
    if (!_projects.contains(name) || !dir.existsSync()) {
      response.statusCode = 404;
      await response.close();
      return;
    }
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(filesToProject(_sources(dir))));
    await response.close();
    return;
  }
  if (request.method != 'POST' || request.uri.path != '/claude') {
    response.statusCode = 404;
    await response.close();
    return;
  }
  Map<String, dynamic> out;
  try {
    final body = jsonDecode(await utf8.decodeStream(request)) as Map;
    out = await _run('${body['prompt'] ?? ''}', body['project']);
  } catch (e) {
    out = {'ok': false, 'reply': 'Bridge error: $e'};
  }
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(out));
  await response.close();
}

Future<Map<String, dynamic>> _run(String prompt, Object? project) async {
  if (prompt.trim().isEmpty) return {'ok': false, 'reply': 'Empty prompt.'};
  final id = DateTime.now().millisecondsSinceEpoch.toString();
  final app = 'build/claude_drafts/$id';
  final dir = Directory('$_root/$app');
  for (final MapEntry(key: path, value: bytes)
      in projectToFiles(project).entries) {
    final file = File('${dir.path}/$path');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  }
  stdout.writeln('[$id] $prompt');

  final started = DateTime.now();
  final model = Platform.environment['CLAUDE_MODEL'];
  final result = await Process.run(
    'claude',
    [
      '-p',
      prompt,
      '--output-format', 'json',
      '--mcp-config', '$_root/.mcp.json',
      '--permission-mode', 'acceptEdits',
      '--allowedTools',
      'mcp__metacode__validate,mcp__metacode__test,mcp__metacode__check,'
          'mcp__metacode__add_labels,mcp__metacode__layout,'
          'mcp__metacode__status,Read,Glob,Grep,Edit,Write',
      '--append-system-prompt', _system(app),
      if (model != null) ...['--model', model],
    ],
    workingDirectory: _root,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final elapsed = DateTime.now().difference(started).inMilliseconds;

  Map<String, dynamic> json = {};
  try {
    json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  } catch (_) {}
  final ok = result.exitCode == 0 && json['is_error'] != true;
  final out = {
    'ok': ok,
    'project': filesToProject(_sources(dir)),
    'reply': '${json['result'] ?? result.stderr}'.trim(),
    'costUsd': (json['total_cost_usd'] as num?)?.toDouble() ?? 0.0,
    'durationMs': (json['duration_ms'] as num?)?.toInt() ?? elapsed,
    'turns': (json['num_turns'] as num?)?.toInt() ?? 0,
  };
  stdout.writeln('[$id] ok=$ok \$${out['costUsd']} ${out['durationMs']}ms');
  if (ok) dir.deleteSync(recursive: true);
  return out;
}

/// The modules the editor may load (GET /project?name=).
const _projects = {'food', 'travel', 'work'};

/// An app folder's sources by path: text files only, `.generated/` and
/// `.state/` (any dot path) dropped.
Map<String, String> _sources(Directory dir) {
  final files = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final path = entity.path.substring(dir.path.length + 1);
    if (path.startsWith('.') || path.contains('/.')) continue;
    if (!RegExp(r'\.(ya?ml|dart|md|json)$').hasMatch(path)) continue;
    files[path] = entity.readAsStringSync();
  }
  return files;
}

String _system(String app) => '''
You are editing ONE small Metacode app, the folder $app (relative to the repo
root), which runs live inside the editor. Change only files in that folder;
never touch examples/ or the engine. The user sees the app, not the code.
Follow the metacode-app skill and its REFERENCE.md for files, widgets and
signatures. Pass app "$app" to the metacode MCP tools; validate every file
you change (mcp__metacode__validate) until it is clean. If the state's shape
changes, update app.yaml and app/models/state.yaml together. Finish with one
short sentence, for the user, on what changed.''';

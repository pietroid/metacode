import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../compiler/build.dart';
import '../files/project_files.dart';
import 'project_config.dart';

/// A project run from its files: compiled in the app (lib/compiler) and
/// compiled again after every change to them, wherever the change came
/// from (an editor saving to disk, another tab, the in-app editor).
///
/// Compiling runs on a background isolate where there is one (not on the
/// web), so the UI keeps running meanwhile.
class LiveProject {
  final ProjectFiles files;

  /// Repo-relative folder of the root app, used in generated code and for
  /// app files (`examples/my_own_app/app/views/style/images/logo.svg`).
  final String path;

  LiveProject(this.files, {this.path = 'examples/my_own_app'});

  /// Compiles the files now. Null (and the issues printed) when invalid.
  /// The outputs (`.generated/`) are written back to [files], so the IDE,
  /// the tests and the web's storage see the same as the CLI writes.
  Future<ProjectConfig?> compile() async {
    final watch = Stopwatch()..start();
    final sources = {
      for (final p in files.paths)
        if (ProjectFiles.isSource(p)) p: files.readBytes(p)!,
    };
    final result = await compute(_compile, (sources, path));
    for (final w in result.warnings) {
      debugPrint('metacode: warning: $w');
    }
    for (final e in result.errors) {
      debugPrint('metacode: error: $e');
    }
    final bundle = result.bundle;
    if (bundle == null) return null;
    unawaited(_write(result.outputs));
    final config = ProjectConfig.fromBundle(jsonDecode(bundle) as Map,
        readFile: readFile);
    debugPrint('metacode: compiled in ${watch.elapsedMilliseconds}ms');
    return config;
  }

  /// An app file by its repo-relative path, from [files].
  Uint8List? readFile(String repoPath) => repoPath.startsWith('$path/')
      ? files.readBytes(repoPath.substring(path.length + 1))
      : null;

  Future<void> _write(Map<String, Object> outputs) async {
    for (final MapEntry(key: path, value: contents) in outputs.entries) {
      if (contents is String) {
        await files.write(path, contents);
      } else {
        await files.writeBytes(path, contents as Uint8List);
      }
    }
  }

  /// A new config after every change to the sources (not to `.generated/`
  /// or `.state/`) that compiles. Changes arriving together (an editor's
  /// save is often several events) compile once; changes during a compile
  /// compile again after it, so the last version always wins.
  Stream<ProjectConfig> watch(
      {Duration debounce = const Duration(milliseconds: 100)}) {
    late StreamController<ProjectConfig> out;
    StreamSubscription<Set<String>>? changes;
    Timer? pending;
    var compiling = false;
    var dirty = false;

    Future<void> run() async {
      if (compiling) {
        dirty = true;
        return;
      }
      compiling = true;
      try {
        do {
          dirty = false;
          try {
            final config = await compile();
            if (config != null && !dirty && !out.isClosed) out.add(config);
          } catch (e, stack) {
            debugPrint('metacode: could not compile: $e\n$stack');
          }
        } while (dirty);
      } finally {
        compiling = false;
      }
    }

    out = StreamController<ProjectConfig>(
      onListen: () {
        changes = files.changes.listen((paths) {
          if (!paths.any(ProjectFiles.isSource)) return;
          pending?.cancel();
          pending = Timer(debounce, run);
        });
      },
      onCancel: () {
        pending?.cancel();
        return changes?.cancel();
      },
    );
    return out.stream;
  }
}

/// [sources] (a project's files by path, the root app's folder) compiled
/// on a background isolate where there is one, without writing anything:
/// the app tree, or null and the errors. Dynamic modules
/// (`miniApp: {project: ..}`) run this on every change to their project.
Future<({ProjectConfig? config, List<String> errors})> compileSources(
    Map<String, Uint8List> sources,
    {String path = 'dynamic'}) async {
  final result = await compute(_compile, (sources, path));
  final bundle = result.bundle;
  if (bundle == null) return (config: null, errors: result.errors);
  return (
    config: ProjectConfig.fromBundle(jsonDecode(bundle) as Map,
        readFile: (repoPath) => repoPath.startsWith('$path/')
            ? sources[repoPath.substring(path.length + 1)]
            : null),
    errors: const <String>[],
  );
}

/// What a compile sends back from its isolate (plain data only).
typedef _Result = ({
  String? bundle,
  Map<String, Object> outputs,
  List<String> errors,
  List<String> warnings,
});

_Result _compile((Map<String, Uint8List>, String) input) {
  final (sources, path) = input;
  final result = build(ProjectFiles(sources), path: path);
  return (
    bundle: result.bundle,
    outputs: result.outputs,
    errors: result.issues.errors,
    warnings: result.issues.warnings,
  );
}

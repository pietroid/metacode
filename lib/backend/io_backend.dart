// A [MetacodeBackend] on real folders (dart:io), as the server runs it: the
// code folder watched (new code compiles and runs without a restart; a
// version that doesn't compile leaves the last one running), and the data
// folder's `shared.yaml` files watched (a value edited by hand, a feature
// toggle, goes to every client).

import 'dart:async';
import 'dart:io';

import '../files/io_project_files.dart';
import '../files/project_files.dart';
import 'backend.dart';

/// The backend for the app in [codeDir], its state in [dataDir]. Null (and
/// the issues printed) when the code doesn't compile.
Future<MetacodeBackend?> openBackend(String codeDir, String dataDir) async {
  await Directory(dataDir).create(recursive: true);
  final code = await IoProjectFiles.open(codeDir, watch: true);
  final data = await IoProjectFiles.open(dataDir);
  final backend = MetacodeBackend(code: code, data: data, path: codeDir);

  void report() {
    for (final e in backend.issues.errors) {
      stderr.writeln('error: $e');
    }
  }

  if (!backend.reload()) {
    report();
    stderr.writeln('metacode backend: $codeDir does not compile');
    return null;
  }

  Timer? pending;
  code.changes.listen((paths) {
    if (!paths.any(ProjectFiles.isSource)) return;
    pending?.cancel();
    pending = Timer(const Duration(milliseconds: 200), () {
      final ok = backend.reload();
      stdout.writeln(ok
          ? 'metacode backend: reloaded'
          : 'metacode backend: the new code does not compile; '
              'still running the last version');
      if (!ok) report();
    });
  });

  final dataRoot = Directory(dataDir).absolute.path;
  Directory(dataDir).watch(recursive: true).listen((event) async {
    if (!event.path.endsWith('shared.yaml')) return;
    // The watcher reports paths as the folder was given (often relative):
    // compare absolute ones.
    final file = File(event.path).absolute;
    if (!file.existsSync() || !file.path.startsWith('$dataRoot/')) return;
    final path = file.path.substring(dataRoot.length + 1);
    final contents = await file.readAsString();
    if (data.read(path) == contents) return; // our own write
    await data.write(path, contents);
    await backend.dataChanged(path);
  });
  return backend;
}

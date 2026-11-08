import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../files/project_files.dart';

/// Where each app's state (`state.yaml`) is saved. [app] names the app by
/// its module folders: `[]` for the root, `['food']` for `modules/food/`.
abstract class StateStore {
  Future<String?> read(List<String> app);
  Future<void> write(List<String> app, String yaml);

  /// The store for running from the bundled bundle.json: the documents
  /// folder (or `METACODE_STATE_PATH`) on desktop and mobile, none on the
  /// web (the state then lives in memory).
  static StateStore? platform(String projectName) =>
      kIsWeb ? null : DocumentsStateStore(projectName);
}

/// State inside the project's files, next to each app's sources:
/// `.state/state.yaml`, `modules/food/.state/state.yaml`. On disk for a
/// folder, in localStorage on the web.
class FilesStateStore implements StateStore {
  final ProjectFiles files;

  FilesStateStore(this.files);

  static String pathOf(List<String> app) =>
      [for (final m in app) ...['modules', m], '.state', 'state.yaml'].join('/');

  @override
  Future<String?> read(List<String> app) async => files.read(pathOf(app));

  @override
  Future<void> write(List<String> app, String yaml) =>
      files.write(pathOf(app), yaml);
}

/// State in the app documents folder: `<projectName>/.state/state.yaml`,
/// `<projectName>/modules/<name>/.state/state.yaml`. The root's can be
/// redirected with `--dart-define=METACODE_STATE_PATH=...`.
class DocumentsStateStore implements StateStore {
  final String projectName;

  DocumentsStateStore(this.projectName);

  static const _overridePath = String.fromEnvironment('METACODE_STATE_PATH');

  Future<File> _file(List<String> app) async {
    if (_overridePath.isNotEmpty && app.isEmpty) return File(_overridePath);
    final dir = await getApplicationDocumentsDirectory();
    return File([
      dir.path,
      projectName,
      for (final m in app) ...['modules', m],
      '.state',
      'state.yaml',
    ].join('/'));
  }

  @override
  Future<String?> read(List<String> app) async {
    final file = await _file(app);
    return file.existsSync() ? file.readAsString() : null;
  }

  @override
  Future<void> write(List<String> app, String yaml) async {
    final file = await _file(app);
    await file.parent.create(recursive: true);
    await file.writeAsString(yaml);
  }
}

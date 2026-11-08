import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../files/project_files.dart';

/// Where each app's state (`state.yaml`) is saved. [app] names the app by
/// its module folders: `[]` for the root, `['food']` for `modules/food/`.
/// [file] is the `.state/` file without `.yaml`: `state`, or `locale` (the
/// language picked with `core.locale.set`, root only).
abstract class StateStore {
  Future<String?> read(List<String> app, {String file = 'state'});
  Future<void> write(List<String> app, String yaml, {String file = 'state'});

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

  static String pathOf(List<String> app, {String file = 'state'}) =>
      [for (final m in app) ...['modules', m], '.state', '$file.yaml'].join('/');

  @override
  Future<String?> read(List<String> app, {String file = 'state'}) async =>
      files.read(pathOf(app, file: file));

  @override
  Future<void> write(List<String> app, String yaml, {String file = 'state'}) =>
      files.write(pathOf(app, file: file), yaml);
}

/// State in the app documents folder: `<projectName>/.state/state.yaml`,
/// `<projectName>/modules/<name>/.state/state.yaml`. The root's can be
/// redirected with `--dart-define=METACODE_STATE_PATH=...`.
class DocumentsStateStore implements StateStore {
  final String projectName;

  DocumentsStateStore(this.projectName);

  static const _overridePath = String.fromEnvironment('METACODE_STATE_PATH');

  Future<File> _file(List<String> app, String file) async {
    if (_overridePath.isNotEmpty && app.isEmpty && file == 'state') {
      return File(_overridePath);
    }
    final dir = await getApplicationDocumentsDirectory();
    return File([
      dir.path,
      projectName,
      for (final m in app) ...['modules', m],
      '.state',
      '$file.yaml',
    ].join('/'));
  }

  @override
  Future<String?> read(List<String> app, {String file = 'state'}) async {
    final f = await _file(app, file);
    return f.existsSync() ? f.readAsString() : null;
  }

  @override
  Future<void> write(List<String> app, String yaml,
      {String file = 'state'}) async {
    final f = await _file(app, file);
    await f.parent.create(recursive: true);
    await f.writeAsString(yaml);
  }
}

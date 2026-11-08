import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../files/local_storage_project_files.dart';
import '../../files/project_files.dart';

/// The project's default files, as the tool last wrote them.
const filesAsset = 'examples/my_own_app/.generated/files.json';

/// The project in localStorage. The first time (or on every launch with
/// `--dart-define=METACODE_RESET_FILES=true`) it is filled from
/// [filesAsset], the project's files as they are on disk.
Future<ProjectFiles?> openProjectFiles() async {
  const reset = bool.fromEnvironment('METACODE_RESET_FILES');
  final seed = jsonDecode(await rootBundle.loadString(filesAsset, cache: false))
      as Map;
  return LocalStorageProjectFiles.open(
    seed: ProjectFiles.decodeSnapshot(seed),
    reset: reset,
  );
}

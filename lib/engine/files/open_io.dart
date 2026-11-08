import 'dart:io';

import '../../files/io_project_files.dart';
import '../../files/project_files.dart';

/// The project folder (absolute, or relative to the working directory)
/// given with `--dart-define=METACODE_PROJECT_DIR=...`, watched. Without it,
/// or when this device cannot see it (a phone), null: the app runs the
/// bundled bundle.json.
Future<ProjectFiles?> openProjectFiles() async {
  const dir = String.fromEnvironment('METACODE_PROJECT_DIR');
  if (dir.isEmpty || !Directory(dir).existsSync()) return null;
  return IoProjectFiles.open(dir, watch: true);
}

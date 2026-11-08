import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'project_files.dart';

/// A project folder on disk, loaded into memory. With `watch`, edits made
/// by anyone (an editor, git, the CLI) land in memory and in [changes].
///
/// Sources and `.state/` are loaded; other hidden paths (`.generated/`,
/// `.DS_Store`) are not, but can be written (the compiler's outputs).
/// `.state/` is not watched: the running app owns it, and the echo of its
/// own frequent writes could otherwise bring back an older state.
class IoProjectFiles extends ProjectFiles {
  final Directory root;
  StreamSubscription<FileSystemEvent>? _watch;

  IoProjectFiles._(this.root, Map<String, Uint8List> files) : super(files);

  static Future<IoProjectFiles> open(String dir, {bool watch = false}) async {
    var root = Directory(dir).absolute;
    // Watch events carry resolved paths (/private/var for /var on macOS).
    if (root.existsSync()) root = Directory(root.resolveSymbolicLinksSync());
    final files = <String, Uint8List>{};
    if (root.existsSync()) {
      for (final f in root.listSync(recursive: true).whereType<File>()) {
        final path = _relative(root, f.path);
        if (path != null && ProjectFiles.isStored(path)) {
          files[path] = f.readAsBytesSync();
        }
      }
    }
    final project = IoProjectFiles._(root, files);
    if (watch) project._startWatching();
    return project;
  }

  void _startWatching() {
    _watch = root.watch(recursive: true).listen((event) {
      final changed = <String, Uint8List?>{};
      _collect(event.path, changed);
      if (event is FileSystemMoveEvent && event.destination != null) {
        _collect(event.destination!, changed);
      }
      if (changed.isNotEmpty) applyExternal(changed);
    });
  }

  /// What is now at [absolute]: a file's bytes, every file of a folder, or
  /// deletes for whatever memory had there.
  void _collect(String absolute, Map<String, Uint8List?> out) {
    final path = _relative(root, absolute);
    if (path == null || !ProjectFiles.isSource(path)) return;
    final type = FileSystemEntity.typeSync(absolute, followLinks: false);
    if (type == FileSystemEntityType.file) {
      try {
        out[path] = File(absolute).readAsBytesSync();
      } on FileSystemException {
        // Gone again (an editor's temp file); its delete event follows.
      }
    } else if (type == FileSystemEntityType.directory) {
      for (final f in Directory(absolute).listSync(recursive: true).whereType<File>()) {
        final p = _relative(root, f.path);
        if (p != null && ProjectFiles.isSource(p)) out[p] = f.readAsBytesSync();
      }
    } else {
      // Deleted: the file, or every file of the folder.
      if (exists(path)) out[path] = null;
      for (final p in list(path, recursive: true)) {
        out[p] = null;
      }
    }
  }

  @override
  Future<void> persist(String path, Uint8List? bytes) async {
    final file = File('${root.path}/$path');
    if (bytes == null) {
      if (file.existsSync()) await file.delete();
    } else {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }
  }

  @override
  Future<void> close() async {
    await _watch?.cancel();
    await super.close();
  }

  /// [absolute] relative to [root], or null when outside it.
  static String? _relative(Directory root, String absolute) {
    final normalized = absolute.replaceAll(r'\', '/');
    final base = '${root.path.replaceAll(r'\', '/')}/';
    if (!normalized.startsWith(base)) return null;
    return normalized.substring(base.length);
  }
}

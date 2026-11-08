// A project's files, held in memory: what the compiler reads and the
// editor writes. Pure Dart (no Flutter, no dart:io), so the tool, the app
// and the web build share it. Backends keep the same folder structure:
//
//   ProjectFiles               memory only (tests, seeds)
//   IoProjectFiles             a real folder, watched (io_project_files.dart)
//   LocalStorageProjectFiles   the browser's localStorage (web)

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

/// Every file of a project by POSIX path relative to its root
/// (`app.yaml`, `modules/food/app/actions/add.dart`). Reads are synchronous
/// from memory; writes update memory, then the backend ([persist]).
///
/// [changes] reports every changed path, whoever changed it (this object,
/// another process editing the folder, another browser tab).
class ProjectFiles {
  final SplayTreeMap<String, Uint8List> _files = SplayTreeMap();
  final _changes = StreamController<Set<String>>.broadcast();

  ProjectFiles([Map<String, Uint8List>? files]) {
    if (files != null) _files.addAll(files);
  }

  /// Text files from a `{path: contents}` map (see [toSnapshot]).
  factory ProjectFiles.fromSnapshot(Map snapshot) =>
      ProjectFiles(decodeSnapshot(snapshot));

  /// Paths that hold sources: no segment starts with `.` (so not
  /// `.generated/`, `.state/`, `.DS_Store`).
  static bool isSource(String path) =>
      !path.split('/').any((s) => s.startsWith('.'));

  /// An app's saved state (`.state/state.yaml`, `modules/food/.state/...`):
  /// not a source, but kept by the backends like one.
  static bool isState(String path) {
    final hidden = path.split('/').where((s) => s.startsWith('.')).toList();
    return hidden.length == 1 && hidden.first == '.state';
  }

  /// What backends load and store: sources and state, not `.generated/`
  /// (rebuilt from the sources) or other hidden files.
  static bool isStored(String path) => isSource(path) || isState(path);

  /// Every path, sorted.
  Iterable<String> get paths => _files.keys;

  bool exists(String path) => _files.containsKey(path);

  Uint8List? readBytes(String path) => _files[path];

  String? read(String path) {
    final bytes = _files[path];
    return bytes == null ? null : utf8.decode(bytes, allowMalformed: true);
  }

  /// Files in [dir] (`''` is the root), sorted; with [recursive], also those
  /// in its sub-folders.
  List<String> list(String dir, {bool recursive = false}) {
    final prefix = dir.isEmpty ? '' : '$dir/';
    return [
      for (final p in _under(prefix))
        if (recursive || !p.substring(prefix.length).contains('/')) p,
    ];
  }

  /// Names of the folders directly in [dir], sorted.
  List<String> directories(String dir) {
    final prefix = dir.isEmpty ? '' : '$dir/';
    final names = SplayTreeSet<String>();
    for (final p in _under(prefix)) {
      final rest = p.substring(prefix.length);
      final slash = rest.indexOf('/');
      if (slash > 0) names.add(rest.substring(0, slash));
    }
    return names.toList();
  }

  bool isDirectory(String dir) => _under('$dir/').isNotEmpty;

  Iterable<String> _under(String prefix) => prefix.isEmpty
      ? _files.keys
      : _files.keys.skipWhile((p) => p.compareTo(prefix) < 0)
          .takeWhile((p) => p.startsWith(prefix));

  Future<void> write(String path, String contents) =>
      writeBytes(path, Uint8List.fromList(utf8.encode(contents)));

  /// Writes [bytes] at [path]; unchanged contents are not rewritten.
  Future<void> writeBytes(String path, Uint8List bytes) async {
    if (_same(_files[path], bytes)) return;
    _files[path] = bytes;
    _changes.add({path});
    await persist(path, bytes);
  }

  Future<void> delete(String path) async {
    if (_files.remove(path) == null) return;
    _changes.add({path});
    await persist(path, null);
  }

  /// Changed paths, in batches.
  Stream<Set<String>> get changes => _changes.stream;

  /// Stores a write ([bytes]) or a delete (null) in the backend. Memory
  /// already has it.
  Future<void> persist(String path, Uint8List? bytes) async {}

  /// For backends: applies changes made outside this object (null deletes)
  /// and reports the paths that really changed.
  void applyExternal(Map<String, Uint8List?> changed) {
    final paths = <String>{};
    for (final MapEntry(key: path, value: bytes) in changed.entries) {
      if (bytes == null) {
        if (_files.remove(path) != null) paths.add(path);
      } else if (!_same(_files[path], bytes)) {
        _files[path] = bytes;
        paths.add(path);
      }
    }
    if (paths.isNotEmpty) _changes.add(paths);
  }

  /// The source files (see [isSource]) that are text, as `{path: contents}`:
  /// the web seed (`.generated/files.json`).
  Map<String, String> toSnapshot() => {
        for (final MapEntry(key: path, value: bytes) in _files.entries)
          if (isSource(path) && isText(path)) path: utf8.decode(bytes),
      };

  static Map<String, Uint8List> decodeSnapshot(Map snapshot) => {
        for (final e in snapshot.entries)
          e.key.toString():
              Uint8List.fromList(utf8.encode(e.value.toString())),
      };

  /// Whether [path] is a text file the compiler reads (not an image).
  static bool isText(String path) =>
      const ['.yaml', '.yml', '.dart', '.json', '.md', '.txt']
          .any(path.endsWith);

  Future<void> close() => _changes.close();

  static bool _same(Uint8List? a, Uint8List b) {
    if (a == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

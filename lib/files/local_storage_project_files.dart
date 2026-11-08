import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'project_files.dart';

/// A project kept in the browser's localStorage, one key per file
/// (`metacode:files/app/views/pages/main_page.yaml`), so the folder
/// structure survives. Edits from other tabs arrive in [changes].
/// Sources and `.state/` are stored; `.generated/` is kept in memory only.
class LocalStorageProjectFiles extends ProjectFiles {
  static const prefix = 'metacode:files/';

  StreamSubscription<web.StorageEvent>? _storage;

  LocalStorageProjectFiles._(super.files);

  /// Opens what localStorage holds. When it holds no sources, or [reset]
  /// is true, [seed] (the project's default files) replaces the sources;
  /// the saved state (`.state/`) stays.
  static Future<LocalStorageProjectFiles> open(
      {Map<String, Uint8List>? seed, bool reset = false}) async {
    final storage = web.window.localStorage;
    var files = _load(storage);
    if (seed != null &&
        (reset || !files.keys.any(ProjectFiles.isSource))) {
      for (final key in files.keys.where(ProjectFiles.isSource).toList()) {
        storage.removeItem('$prefix$key');
        files.remove(key);
      }
      for (final MapEntry(key: path, value: bytes) in seed.entries) {
        if (!ProjectFiles.isSource(path)) continue;
        storage.setItem('$prefix$path', _encode(path, bytes));
        files[path] = bytes;
      }
    }
    final project = LocalStorageProjectFiles._(files);
    project._storage = web.EventStreamProviders.storageEvent
        .forTarget(web.window)
        .listen(project._onStorage);
    return project;
  }

  static Map<String, Uint8List> _load(web.Storage storage) {
    final files = <String, Uint8List>{};
    for (var i = 0; i < storage.length; i++) {
      final key = storage.key(i);
      if (key == null || !key.startsWith(prefix)) continue;
      final value = storage.getItem(key);
      if (value != null) files[key.substring(prefix.length)] = _decode(value);
    }
    return files;
  }

  /// Another tab wrote (or the user cleared storage).
  void _onStorage(web.StorageEvent event) {
    final key = event.key;
    if (key == null) {
      // clear(): everything is gone.
      applyExternal({for (final p in paths.toList()) p: null});
      return;
    }
    if (!key.startsWith(prefix)) return;
    final value = event.newValue;
    applyExternal({key.substring(prefix.length): value == null ? null : _decode(value)});
  }

  /// Only sources and state are stored: `.generated/` is rebuilt from the
  /// sources, so it stays in memory and leaves localStorage's few MB to the
  /// project.
  @override
  Future<void> persist(String path, Uint8List? bytes) async {
    if (!ProjectFiles.isStored(path)) return;
    final storage = web.window.localStorage;
    if (bytes == null) {
      storage.removeItem('$prefix$path');
    } else {
      storage.setItem('$prefix$path', _encode(path, bytes));
    }
  }

  @override
  Future<void> close() async {
    await _storage?.cancel();
    await super.close();
  }

  // Text is stored as is, anything else (images, bytecode) as base64.
  static String _encode(String path, Uint8List bytes) => ProjectFiles.isText(path)
      ? 't:${utf8.decode(bytes)}'
      : 'b:${base64Encode(bytes)}';

  static Uint8List _decode(String value) => value.startsWith('b:')
      ? base64Decode(value.substring(2))
      : Uint8List.fromList(utf8.encode(value.substring(2)));
}

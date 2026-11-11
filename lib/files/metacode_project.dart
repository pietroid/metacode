// A whole Metacode project as data: the built-in `metacodeProject` model
// (lib/compiler/models.dart `projectModels`), as JSON. A project in an app's
// state runs as a dynamic module (`miniApp: {project: <value>}`).
//
// ```
// {files: [{name: app.yaml, content: '...'}],
//  folders: [{name: app, files: [...], folders: [...]}]}
// ```

import 'dart:convert';
import 'dart:typed_data';

/// The files of [project] (a `metacodeProject` as JSON) by path:
/// `app.yaml`, `app/views/pages/main_page.yaml`. Entries with an empty or
/// unsafe name (`..`, a `/`) are skipped; so is anything malformed.
Map<String, Uint8List> projectToFiles(Object? project) {
  final out = <String, Uint8List>{};
  bool safe(Object? name) =>
      name is String &&
      name.isNotEmpty &&
      name != '.' &&
      name != '..' &&
      !name.contains('/') &&
      !name.contains(r'\');
  void folder(Object? json, String prefix) {
    if (json is! Map) return;
    for (final file in (json['files'] as List?) ?? const []) {
      if (file is! Map || !safe(file['name'])) continue;
      out['$prefix${file['name']}'] =
          utf8.encode((file['content'] ?? '').toString());
    }
    for (final sub in (json['folders'] as List?) ?? const []) {
      if (sub is! Map || !safe(sub['name'])) continue;
      folder(sub, '$prefix${sub['name']}/');
    }
  }

  folder(project, '');
  return out;
}

/// [files] (text files by path) as a `metacodeProject` (JSON): the
/// inverse of [projectToFiles], folders and files sorted by name.
Map<String, dynamic> filesToProject(Map<String, String> files) {
  Map<String, dynamic> folder(Map<String, String> files) {
    final own = <Map<String, dynamic>>[];
    final subs = <String, Map<String, String>>{};
    for (final MapEntry(key: path, value: content) in files.entries) {
      final slash = path.indexOf('/');
      if (slash < 0) {
        own.add({'name': path, 'content': content});
      } else {
        (subs[path.substring(0, slash)] ??= {})[path.substring(slash + 1)] =
            content;
      }
    }
    own.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return {
      'files': own,
      'folders': [
        for (final name in subs.keys.toList()..sort())
          {'name': name, ...folder(subs[name]!)},
      ],
    };
  }

  return folder(files);
}

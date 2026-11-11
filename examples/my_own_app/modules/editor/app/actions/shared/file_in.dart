// fileIn: The content of the file at [path] (`app/views/pages/main_page.yaml`)
// in [project], or null when it has none.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';

String? fileIn(MetacodeProject project, String path) {
  final parts = path.split('/');
  var files = project.files;
  var folders = project.folders;
  for (var i = 0; i < parts.length - 1; i++) {
    final matches = folders.where((MetacodeFolder f) => f.name == parts[i]).toList();
    if (matches.isEmpty) return null;
    files = matches.first.files;
    folders = matches.first.folders;
  }
  for (final f in files) {
    if (f.name == parts.last) return f.content;
  }
  return null;
}

void main() {
  test('fileIn finds a file in nested folders', () {
    final project = MetacodeProject(files: [], folders: [
      MetacodeFolder(name: 'app', files: [], folders: [
        MetacodeFolder(
            name: 'x', files: [MetacodeFile(name: 'a.yaml', content: 'A')], folders: []),
      ]),
    ]);
    expect(fileIn(project, 'app/x/a.yaml'), 'A');
    expect(fileIn(project, 'app/y/a.yaml'), isNull);
  });
}

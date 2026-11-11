// withFile: [project] with the file at [path] set to [content] (added, with
// its folders, when missing). The project is not changed.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';

MetacodeProject withFile(MetacodeProject project, String path, String content) {
  final root = _withFileIn(
      MetacodeFolder(name: '', files: project.files, folders: project.folders),
      path.split('/'),
      content);
  return MetacodeProject(files: root.files, folders: root.folders);
}

MetacodeFolder _withFileIn(
    MetacodeFolder folder, List<String> parts, String content) {
  final name = parts.first;
  if (parts.length == 1) {
    final files = <MetacodeFile>[];
    var found = false;
    for (final f in folder.files) {
      if (f.name == name) {
        files.add(MetacodeFile(name: name, content: content));
        found = true;
      } else {
        files.add(f);
      }
    }
    if (!found) files.add(MetacodeFile(name: name, content: content));
    return MetacodeFolder(name: folder.name, files: files, folders: folder.folders);
  }
  final rest = parts.sublist(1);
  final folders = <MetacodeFolder>[];
  var found = false;
  for (final f in folder.folders) {
    if (f.name == name) {
      folders.add(_withFileIn(f, rest, content));
      found = true;
    } else {
      folders.add(f);
    }
  }
  if (!found) {
    folders.add(_withFileIn(
        MetacodeFolder(name: name, files: [], folders: []), rest, content));
  }
  return MetacodeFolder(name: folder.name, files: folder.files, folders: folders);
}

void main() {
  test('withFile replaces a nested file and adds missing ones', () {
    final empty = MetacodeProject(files: [], folders: []);
    final one = withFile(empty, 'app/x/a.yaml', 'A');
    expect(one.folders.single.folders.single.files.single.content, 'A');
    final two = withFile(one, 'app/x/a.yaml', 'B');
    expect(two.folders.single.folders.single.files.single.content, 'B');
    expect(one.folders.single.folders.single.files.single.content, 'A');
  });
}

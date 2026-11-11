// projectTitle: The name of the example app at `index` (projectNames), as
// its ProjectTile shows it.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import '../../actions/shared/project_names.dart';
import 'shared/title_of.dart';

String projectTitle(State state, Labels labels, int index) {
  final names = projectNames();
  return titleOf(labels, names[index]);
}

void main() {
  test('projectTitle names each project', () {
    expect(app.projectTitle(sample(), 0), 'Food');
    expect(app.projectTitle(sample(), 2), 'Work');
  });
}

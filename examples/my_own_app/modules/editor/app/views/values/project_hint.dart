// projectHint: One line on what the example app at `index` (projectNames)
// is, under its title in ProjectTile.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../actions/shared/project_names.dart';
import '../../models/sample.dart';

String projectHint(State state, Labels labels, int index) {
  final names = projectNames();
  final name = names[index];
  if (name == 'food') return labels.foodHint;
  if (name == 'travel') return labels.travelHint;
  return labels.workHint;
}

void main() {
  test('projectHint describes each project', () {
    expect(app.projectHint(sample(), 1), contains('trip'));
  });
}

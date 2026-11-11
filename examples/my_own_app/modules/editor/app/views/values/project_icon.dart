// projectIcon: The icon of the example app at `index` (projectNames).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../actions/shared/project_names.dart';
import '../../models/sample.dart';

String projectIcon(State state, int index) {
  final names = projectNames();
  final name = names[index];
  if (name == 'food') return 'restaurant';
  if (name == 'travel') return 'flight';
  return 'work';
}

void main() {
  test('projectIcon picks one per project', () {
    expect(app.projectIcon(sample(), 0), 'restaurant');
    expect(app.projectIcon(sample(), 2), 'work');
  });
}

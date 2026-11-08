// openCourseSummary: The open course's summary, in the course sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_course.dart';
import 'shared/tr.dart';

String openCourseSummary(State state, Labels labels) => tr(currentCourse(state).summary, labels);

void main() {
  test('openCourseSummary', () {
    expect(app.openCourseSummary(sample(courseIndex: 1)), 'All about the moon.');
  });
}

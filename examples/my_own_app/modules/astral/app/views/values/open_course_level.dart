// openCourseLevel: The open course's level, in the course sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_course.dart';
import 'shared/tr.dart';

String openCourseLevel(State state, Labels labels) => tr(currentCourse(state).level, labels);

void main() {
  test('openCourseLevel', () {
    expect(app.openCourseLevel(sample(courseIndex: 1)), 'Beginner');
  });
}

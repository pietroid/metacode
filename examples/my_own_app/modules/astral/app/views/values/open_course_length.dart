// openCourseLength: The open course's length, in the course sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_course.dart';
import 'shared/tr.dart';

String openCourseLength(State state, Labels labels) => tr(currentCourse(state).length, labels);

void main() {
  test('openCourseLength', () {
    expect(app.openCourseLength(sample(courseIndex: 1)), '6 lessons');
  });
}

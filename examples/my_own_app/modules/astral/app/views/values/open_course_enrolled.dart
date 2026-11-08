// openCourseEnrolled: Whether the visitor is enrolled in the open course (the sheet shows a confirmation instead of the button).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool openCourseEnrolled(State state) => state.enrolledCourse == state.courseIndex;

void main() {
  test('openCourseEnrolled', () {
    expect(app.openCourseEnrolled(sample(courseIndex: 1, enrolledCourse: 1)), true);
    expect(app.openCourseEnrolled(sample()), false);
  });
}

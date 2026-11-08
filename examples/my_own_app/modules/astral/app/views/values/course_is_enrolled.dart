// courseIsEnrolled: Whether the visitor is enrolled in course [index] (its card shows a tag).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool courseIsEnrolled(State state, int index) => state.enrolledCourse.round() == index;

void main() {
  test('courseIsEnrolled', () {
    expect(app.courseIsEnrolled(sample(enrolledCourse: 1), 1), true);
    expect(app.courseIsEnrolled(sample(), 0), false);
  });
}

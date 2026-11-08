// openCourseTitle: The open course's title, in the course sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_course.dart';
import 'shared/tr.dart';

String openCourseTitle(State state, Labels labels) => tr(currentCourse(state).title, labels);

void main() {
  test('openCourseTitle', () {
    expect(app.openCourseTitle(sample(courseIndex: 1)), 'Moon');
  });
}

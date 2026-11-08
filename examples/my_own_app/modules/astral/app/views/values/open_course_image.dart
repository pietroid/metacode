// openCourseImage: The open course's cover image, on top of the course sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_course.dart';

String openCourseImage(State state) => currentCourse(state).image;

void main() {
  test('openCourseImage', () {
    expect(app.openCourseImage(sample(courseIndex: 1)), 'moon.jpg');
  });
}

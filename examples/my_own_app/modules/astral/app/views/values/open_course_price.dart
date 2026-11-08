// openCoursePrice: The open course's price, in the course sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_course.dart';
import 'shared/tr.dart';

String openCoursePrice(State state, Labels labels) => tr(currentCourse(state).price, labels);

void main() {
  test('openCoursePrice', () {
    expect(app.openCoursePrice(sample(courseIndex: 1)), '\$149');
  });
}

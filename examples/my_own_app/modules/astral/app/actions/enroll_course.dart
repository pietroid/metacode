// enrollCourse: Enrolls the visitor in the open course (one at a time).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> enrollCourse(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(enrolledCourse: state.courseIndex));
}

void main() {
  test('enrollCourse', () async {
    expect((await app.enrollCourse(sample(courseIndex: 1))).enrolledCourse, 1);
  });
}

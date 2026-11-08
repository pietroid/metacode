// openCourse: Opens course [index] of the carousel in the course sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openCourse(State state, void Function(StateDelta) emit, Core core, int index) async {
  emit(StateDelta(courseIndex: index));
  core.navigator.push(Routes.course);
}

void main() {
  test('openCourse', () async {
    final s = await app.openCourse(sample(), 1);
    expect(s.courseIndex, 1);
    expect(app.navigation, ['push course']);
  });
}

// openFoundation: Opens the foundation course (the first) in the course
// sheet: the banner's call to action.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openFoundation(State state, void Function(StateDelta) emit, Core core) async {
  emit(StateDelta(courseIndex: 0));
  core.navigator.push(Routes.course);
}

void main() {
  test('openFoundation', () async {
    final s = await app.openFoundation(sample(courseIndex: 1));
    expect(s.courseIndex, 0);
    expect(app.navigation, ['push course']);
  });
}

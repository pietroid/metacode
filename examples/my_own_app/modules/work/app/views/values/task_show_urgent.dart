// taskShowUrgent: Whether a to-do shows the Urgent tag: urgent and still open.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool taskShowUrgent(State state, int index) {
  final t = state.tasks[index];
  return t.urgent && !t.done;
}

void main() {
  test('taskShowUrgent', () {
    expect(app.taskShowUrgent(sample(), 0), isTrue);
    expect(app.taskShowUrgent(sample(), 1), isFalse);
  });
}

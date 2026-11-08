// taskCount: How many to-dos are open, for the To-do header.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String taskCount(State state, Labels labels) {
  var n = 0;
  for (final t in state.tasks) {
    if (!t.done) n++;
  }
  return '$n ${labels.open}';
}

void main() {
  test('taskCount', () {
    expect(app.taskCount(sample()), '1 open');
  });
}

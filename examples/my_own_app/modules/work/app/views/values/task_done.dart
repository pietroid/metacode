// taskDone: Whether a to-do is done.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool taskDone(State state, int index) => state.tasks[index].done;

void main() {
  test('taskDone', () {
    expect(app.taskDone(sample(), 1), isTrue);
  });
}

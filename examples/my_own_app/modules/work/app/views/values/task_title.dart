// taskTitle: A to-do's title.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String taskTitle(State state, int index) => state.tasks[index].title;

void main() {
  test('taskTitle', () {
    expect(app.taskTitle(sample(), 0), 'Review budget');
  });
}

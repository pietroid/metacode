// taskList: The to-dos.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Task> taskList(State state) => state.tasks;

void main() {
  test('taskList', () {
    expect(app.taskList(sample()).length, 2);
  });
}

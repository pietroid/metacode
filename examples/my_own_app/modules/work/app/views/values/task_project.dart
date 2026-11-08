// taskProject: The project a to-do belongs to.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String taskProject(State state, int index) => state.tasks[index].project;

void main() {
  test('taskProject', () {
    expect(app.taskProject(sample(), 0), 'Finance');
  });
}

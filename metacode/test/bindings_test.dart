import 'package:flutter_test/flutter_test.dart';

import '../generated/state.dart';
import 'fixtures.dart';

void main() {
  test('state.yaml loads and is usable', () {
    expect(app.taskList(app.initialState), isA<List<Task>>());
  });

  test('taskList follows the filter', () {
    expect(app.taskList(sample()).length, 2);
    expect(app.taskList(sample(filter: Filter.open)).single.title, 'Buy milk');
    expect(app.taskList(sample(filter: Filter.done)).single.title, 'Walk the dog');
  });

  test('item bindings read the visible task at index', () {
    final s = sample(filter: Filter.done);
    expect(app.taskTitle(s, 0), 'Walk the dog');
    expect(app.taskDone(s, 0), true);
    expect(app.taskDate(s, 0), '2026-11-04');
  });

  test('draftValue', () {
    expect(app.draftValue(sample(draft: 'x')), 'x');
  });

  test('completed tasks', () {
    expect(app.hasCompletedTasks(sample()), true);
    expect(app.clearCompletedText(sample()), '1 completed');
    expect(app.hasCompletedTasks(app.clearCompleted(sample())), false);
  });

  test('filter flags', () {
    expect(app.filterIsAll(sample()), true);
    expect(app.filterIsOpen(sample(filter: Filter.open)), true);
    expect(app.filterIsDone(sample()), false);
  });
}

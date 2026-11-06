import 'package:flutter_test/flutter_test.dart';

import '../generated/state.dart';
import 'fixtures.dart';

void main() {
  test('updateDraft stores the input value', () {
    expect(app.updateDraft(sample(), 'Read').draft, 'Read');
  });

  test('addTask appends the draft and clears it', () {
    final next = app.addTask(sample(draft: 'Read'));
    expect(next.tasks.map((t) => t.title), ['Buy milk', 'Walk the dog', 'Read']);
    expect(next.tasks.last.done, false);
    expect(next.draft, '');
  });

  test('addTask ignores an empty draft', () {
    expect(app.addTask(sample()).tasks.length, 2);
  });

  test('toggleTask uses the index in the visible (filtered) list', () {
    final next = app.toggleTask(sample(filter: Filter.done), 0);
    expect(next.tasks[1].done, false); // "Walk the dog" was the only done task
    expect(next.tasks[0].done, false);
  });

  test('deleteTask removes the visible task at index', () {
    final next = app.deleteTask(sample(filter: Filter.open), 0);
    expect(next.tasks.map((t) => t.title), ['Walk the dog']);
  });

  test('clearCompleted keeps only open tasks', () {
    expect(app.clearCompleted(sample()).tasks.map((t) => t.title), ['Buy milk']);
  });

  test('filter actions', () {
    expect(app.setFilterOpen(sample()).filter, Filter.open);
    expect(app.setFilterDone(sample()).filter, Filter.done);
    expect(app.setFilterAll(sample(filter: Filter.done)).filter, Filter.all);
  });
}

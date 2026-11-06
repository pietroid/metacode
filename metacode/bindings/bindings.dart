// Bindings read the state for the UI. Each one receives the current [State]
// (plus `index` when used inside a list item) and returns a value.

import '../generated/state.dart';

List<Task> visibleTasks(State state) {
  if (state.filter == Filter.open) {
    return state.tasks.where((Task task) => !task.done).toList();
  }
  if (state.filter == Filter.done) {
    return state.tasks.where((Task task) => task.done).toList();
  }
  return state.tasks;
}

List<Task> taskList(State state) => visibleTasks(state);

String draftValue(State state) => state.draft;

String taskTitle(State state, int index) => visibleTasks(state)[index].title;

bool taskDone(State state, int index) => visibleTasks(state)[index].done;

String taskDate(State state, int index) =>
    visibleTasks(state)[index].createdAt.toIso8601String().substring(0, 10);

bool hasCompletedTasks(State state) => state.tasks.any((Task task) => task.done);

String clearCompletedText(State state) {
  final count = state.tasks.where((Task task) => task.done).length;
  return '$count completed';
}

bool filterIsAll(State state) => state.filter == Filter.all;

bool filterIsOpen(State state) => state.filter == Filter.open;

bool filterIsDone(State state) => state.filter == Filter.done;

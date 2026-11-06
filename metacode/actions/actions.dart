// Actions are transfer functions: NextState = action(CurrentState).
//
// Each action receives the current [State] (plus event params matched by name:
// `index` inside list items, `value` from inputs) and returns the next state.
// The state is a fresh copy, so changing it in place and returning it is fine;
// `copyWith` is there when you prefer building a new one.

import '../generated/state.dart';
import '../bindings/bindings.dart';

State updateDraft(State state, String value) => state.copyWith(draft: value);

State addTask(State state) {
  if (state.draft.isEmpty) return state;
  state.tasks.add(Task(title: state.draft, done: false, createdAt: DateTime.now()));
  return state.copyWith(draft: '');
}

State toggleTask(State state, int index) {
  final task = visibleTasks(state)[index];
  task.done = !task.done;
  return state;
}

State deleteTask(State state, int index) {
  state.tasks.remove(visibleTasks(state)[index]);
  return state;
}

State clearCompleted(State state) {
  state.tasks.removeWhere((Task task) => task.done);
  return state;
}

State setFilterAll(State state) => state.copyWith(filter: Filter.all);

State setFilterOpen(State state) => state.copyWith(filter: Filter.open);

State setFilterDone(State state) => state.copyWith(filter: Filter.done);

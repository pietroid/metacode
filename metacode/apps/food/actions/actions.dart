// Actions react to the UI. Each one receives the current [State] plus, by
// name: `emit` (apply a StateDelta), `core` (api + navigator), `index`
// inside list items and `value` from inputs.

import '../generated/state.dart';

// Log servings

Future<void> addFood(State state, void Function(StateDelta) emit, int index) async {
  state.foods[index].count += 1;
  emit(StateDelta(foods: state.foods));
}

Future<void> removeFood(State state, void Function(StateDelta) emit, int index) async {
  if (state.foods[index].count <= 0) return;
  state.foods[index].count -= 1;
  emit(StateDelta(foods: state.foods));
}

Future<void> clearFoods(State state, void Function(StateDelta) emit) async {
  for (final f in state.foods) {
    f.count = 0;
  }
  emit(StateDelta(foods: state.foods));
}

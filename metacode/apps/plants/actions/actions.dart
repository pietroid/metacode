// Actions react to the UI. Each one receives the current [State] plus, by
// name: `emit` (apply a StateDelta), `core` (api + navigator), `index`
// inside list items and `value` from inputs.

import '../generated/state.dart';

// Water and pass the days

Future<void> waterPlant(State state, void Function(StateDelta) emit, int index) async {
  state.plants[index].daysLeft = state.plants[index].everyDays;
  emit(StateDelta(plants: state.plants));
}

Future<void> nextDay(State state, void Function(StateDelta) emit) async {
  for (final p in state.plants) {
    if (p.daysLeft > 0) p.daysLeft -= 1;
  }
  emit(StateDelta(plants: state.plants));
}

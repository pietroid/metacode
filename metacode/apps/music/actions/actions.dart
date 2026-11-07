// Actions react to the UI. Each one receives the current [State] plus, by
// name: `emit` (apply a StateDelta), `core` (api + navigator), `index`
// inside list items and `value` from inputs.

import '../generated/state.dart';

// Chords and practice

Future<void> toggleChord(State state, void Function(StateDelta) emit, int index, bool value) async {
  state.chords[index].learned = value;
  emit(StateDelta(chords: state.chords));
}

Future<void> logPractice(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(practiceMinutes: state.practiceMinutes + 5));

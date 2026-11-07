// Relations turn the state into values for the UI.

import '../generated/state.dart';

double _capAtOne(num p) {
  final double d = p.toDouble();
  if (d > 1) return 1.0;
  return d;
}

List<Chord> chordList(State state) => state.chords;

String chordName(State state, int index) => state.chords[index].name;
String chordFingers(State state, int index) => state.chords[index].fingers;
bool chordLearned(State state, int index) => state.chords[index].learned;

int _learnedCount(State state) => state.chords.where((Chord c) => c.learned).length;

String chordsText(State state) => '${_learnedCount(state)} of ${state.chords.length} chords learned';

double chordsProgress(State state) {
  if (state.chords.isEmpty) return 0.0;
  return _capAtOne(_learnedCount(state) / state.chords.length);
}

bool _knows(State state, String name) =>
    state.chords.any((Chord c) => c.name == name && c.learned);

String musicTip(State state) {
  if (_knows(state, 'G') && _knows(state, 'C') && _knows(state, 'D') && _knows(state, 'Em')) {
    if (_learnedCount(state) == state.chords.length) {
      return 'You know all six. Next week: strumming patterns.';
    }
    return 'G, C, D and Em: those four chords play hundreds of pop songs. You can start one today.';
  }
  for (final c in state.chords) {
    if (!c.learned) return 'Next up: ${c.name}. ${c.fingers}.';
  }
  return 'Pick a chord to start.';
}

String practiceText(State state) {
  final m = state.practiceMinutes.round();
  if (m >= 10) return '$m min today. Goal reached';
  return '$m of 10 min today';
}

double practiceProgress(State state) {
  return _capAtOne(state.practiceMinutes / 10);
}

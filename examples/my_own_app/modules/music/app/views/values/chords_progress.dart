// chordsProgress: The share of chords already learned.
import '../../../.generated/state.dart';

double _chordsProgressCapAtOne(num p) {
  final double d = p.toDouble();
  if (d > 1) return 1.0;
  return d;
}

int _chordsProgressLearnedCount(State state) =>
    state.chords.where((Chord c) => c.learned).length;

double chordsProgress(State state) {
  if (state.chords.isEmpty) return 0.0;
  return _chordsProgressCapAtOne(
    _chordsProgressLearnedCount(state) / state.chords.length,
  );
}

// chordsText returns the formatted count of learned chords.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

int _chordsTextLearnedCount(State state) =>
    state.chords.where((Chord c) => c.learned).length;

String chordsText(State state, Labels labels) =>
    '${_chordsTextLearnedCount(state)} ${labels.of} ${state.chords.length} ${labels.chordsLearned}';

void main() {
  test('chordsText', () {
    expect(app.chordsText(app.initialState), '2 of 6 chords learned');
    expect(app.chordsText(sample()), '1 of 2 chords learned');
  });
}

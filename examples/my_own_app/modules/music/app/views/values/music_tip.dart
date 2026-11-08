// musicTip suggests the next chord or a milestone based on learned chords.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

int _musicTipLearnedCount(State state) =>
    state.chords.where((Chord c) => c.learned).length;

bool _musicTipKnows(State state, String name) =>
    state.chords.any((Chord c) => c.name == name && c.learned);

String musicTip(State state, Labels labels) {
  if (_musicTipKnows(state, 'G') &&
      _musicTipKnows(state, 'C') &&
      _musicTipKnows(state, 'D') &&
      _musicTipKnows(state, 'Em')) {
    if (_musicTipLearnedCount(state) == state.chords.length) {
      return labels.tipAllSix;
    }
    return labels.tipFourChords;
  }
  for (final c in state.chords) {
    if (!c.learned) return '${labels.nextUp} ${c.name}. ${c.fingers}.';
  }
  return labels.tipPickChord;
}

void main() {
  test('musicTip', () {
    expect(app.musicTip(sample()), startsWith('Next up: G.'));
    final four = sample(
      chords: [
        for (final n in ['G', 'C', 'D', 'Em'])
          Chord(name: n, fingers: '', learned: true),
        Chord(name: 'F', fingers: '', learned: false),
      ],
    );
    expect(app.musicTip(four), contains('hundreds of pop songs'));
  });
}

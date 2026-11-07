import 'package:flutter_test/flutter_test.dart';

import '../generated/state.dart';
import 'fixtures.dart';

void main() {
  test('state.yaml loads and is usable', () {
    expect(app.chordsText(app.initialState), '2 of 6 chords learned');
  });

  test('music progress and tips', () {
    expect(app.chordsText(sample()), '1 of 2 chords learned');
    expect(app.musicTip(sample()), startsWith('Next up: G.'));
    expect(app.practiceText(sample(practiceMinutes: 5)), '5 of 10 min today');
    expect(app.practiceProgress(sample(practiceMinutes: 20)), 1.0);
    final four = sample(chords: [
      for (final n in ['G', 'C', 'D', 'Em']) Chord(name: n, fingers: '', learned: true),
      Chord(name: 'F', fingers: '', learned: false),
    ]);
    expect(app.musicTip(four), contains('hundreds of pop songs'));
  });
}

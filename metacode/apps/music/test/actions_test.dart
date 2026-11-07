import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('chords and practice', () async {
    expect((await app.toggleChord(sample(), 1, true)).chords[1].learned, isTrue);
    expect((await app.logPractice(sample(practiceMinutes: 5))).practiceMinutes, 10);
  });
}

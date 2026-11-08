// toggleChord: Flips whether a chord has been learned.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> toggleChord(
  State state,
  void Function(StateDelta) emit,
  int index,
  bool value,
) async {
  state.chords[index].learned = value;
  emit(StateDelta(chords: state.chords));
}

void main() {
  test('toggleChord marks a chord as learned', () async {
    final s = await app.toggleChord(sample(), 1, true);
    expect(s.chords[1].learned, isTrue);
  });
}

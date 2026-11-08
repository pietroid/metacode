// donePicking: Ends the swipe early with what is picked so far (even a single recipe).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> donePicking(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(deckPos: state.deck.length));
}

void main() {
  test('donePicking', () async {
    final s = await app.donePicking(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0, 3], deckPos: 1, picked: [12]));
    expect(s.deckPos, 3);
    expect(app.deckDone(s), true);
  });
}

// refuseRecipe: Skips the current recipe card and shows the next.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> refuseRecipe(State state, void Function(StateDelta) emit) async {
  if (state.deckPos < state.deck.length) emit(StateDelta(deckPos: state.deckPos + 1));
}

void main() {
  test('refuseRecipe', () async {
    final s = await app.refuseRecipe(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: []));
    expect(s.picked, isEmpty);
    expect(s.deckPos, 1);
  });
}

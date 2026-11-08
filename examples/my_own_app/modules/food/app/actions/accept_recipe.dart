// acceptRecipe: Accepts the current recipe card and shows the next.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> acceptRecipe(State state, void Function(StateDelta) emit) async {
  if (state.deckPos >= state.deck.length) return;
  state.picked.add(state.deck[state.deckPos.toInt()]);
  emit(StateDelta(picked: state.picked, deckPos: state.deckPos + 1));
}

void main() {
  test('acceptRecipe', () async {
    final s = await app.acceptRecipe(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: []));
    expect(s.picked, [12]);
    expect(s.deckPos, 1);
  });
}

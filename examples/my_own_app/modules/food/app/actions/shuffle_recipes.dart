// shuffleRecipes: Deals the deck again from the start, staying on the swipe.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/deal_deck.dart';

Future<void> shuffleRecipes(State state, void Function(StateDelta) emit) async {
  if (state.program < 0) return;
  emit(StateDelta(deck: dealDeck(state), deckPos: 0, picked: []));
}

void main() {
  test('shuffleRecipes', () async {
    final s = await app.shuffleRecipes(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [3], deckPos: 1, picked: [3]));
    expect(s.deckPos, 0);
    expect(s.picked, isEmpty);
    expect(s.deck.length, 8);
    expect(app.navigation, isEmpty);
  });
}

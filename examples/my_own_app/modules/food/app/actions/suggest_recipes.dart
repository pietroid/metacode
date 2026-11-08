// suggestRecipes: Deals a fresh recipe deck for the program (dealDeck) and opens the swipe over the plan.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/deal_deck.dart';

Future<void> suggestRecipes(State state, void Function(StateDelta) emit, Core core) async {
  if (state.program < 0) return;
  emit(StateDelta(deck: dealDeck(state), deckPos: 0, picked: []));
  core.navigator.push(Routes.swipe);
}

void main() {
  test('suggestRecipes', () async {
    final s = await app.suggestRecipes(sample(goal: Goal.weightLoss, program: 8));
    expect(app.navigation, ['push swipe']);
    expect(s.deck.length, 8);
    expect(s.deck.first, 18); // turkey wraps: an omnivore program starts with meat
    final v = await app.suggestRecipes(sample(goal: Goal.lowCarb, program: 3, prefs: ['vegan', 'nutFree']));
    expect(v.deck, [0, 2, 6, 7]);
  });
}

// cardCost: What the current recipe's ingredients cost.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_card.dart';
import 'shared/has_card.dart';
import 'shared/money.dart';
import 'shared/recipe_cost.dart';

String cardCost(State state, Labels labels) {
  if (!hasCard(state)) return '';
  return money(recipeCost(currentCard(state)), labels);
}

void main() {
  test('cardCost', () async {
    expect(app.cardCost(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: [])), r'$14.00');
  });
}

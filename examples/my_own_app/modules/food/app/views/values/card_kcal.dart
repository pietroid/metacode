// cardKcal: The current recipe's kcal.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_card.dart';
import 'shared/group_digits.dart';
import 'shared/has_card.dart';
import 'shared/recipe_kcal.dart';

String cardKcal(State state, Labels labels) {
  if (!hasCard(state)) return '';
  return '${groupDigits(recipeKcal(currentCard(state)), labels.thousandsSep)} ${labels.kcal}';
}

void main() {
  test('cardKcal', () async {
    expect(app.cardKcal(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: [])), '640 kcal');
  });
}

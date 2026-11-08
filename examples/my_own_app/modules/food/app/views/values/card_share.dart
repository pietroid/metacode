// cardShare: The current recipe's share of the program's daily kcal.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_card.dart';
import 'shared/has_card.dart';
import 'shared/has_program.dart';
import 'shared/recipe_kcal.dart';

String cardShare(State state, Labels labels) {
  if (!hasCard(state) || !hasProgram(state)) return '';
  final daily = state.programs[state.program.toInt()].kcal;
  final pct = (recipeKcal(currentCard(state)) * 100 / daily).round();
  return '$pct% ${labels.ofYourDay}';
}

void main() {
  test('cardShare', () async {
    expect(app.cardShare(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: [])), '40% of your daily kcal');
  });
}

// pickedInfo: An accepted recipe's kcal and cost.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/group_digits.dart';
import 'shared/money.dart';
import 'shared/recipe_cost.dart';
import 'shared/recipe_kcal.dart';

String pickedInfo(State state, Labels labels, int index) {
  final r = state.recipes[state.picked[index].toInt()];
  return '${groupDigits(recipeKcal(r), labels.thousandsSep)} ${labels.kcal} · ${money(recipeCost(r), labels)}';
}

void main() {
  test('pickedInfo', () async {
    expect(app.pickedInfo(sample(goal: Goal.weightLoss, program: 8).copyWith(picked: [12, 0]), 1), r'575 kcal · $10.50');
  });
}

// addBudgetDraft: Adds the typed custom amount to the selected day's food
// budget and clears it; does nothing when it is not a positive number.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/parse_amount.dart';
import 'shared/with_food_added.dart';

Future<void> addBudgetDraft(
  State state,
  void Function(StateDelta) emit,
) async {
  final n = parseAmount(state.budgetDraft);
  if (n <= 0) return;
  emit(StateDelta(trips: withFoodAdded(state, n), budgetDraft: ''));
}

void main() {
  test('addBudgetDraft adds a typed amount', () async {
    final s = await app.addBudgetDraft(sample(budgetDraft: '12,5'));
    expect(s.trips[0].days[0].food, 52.5);
    expect(s.budgetDraft, '');
  });
  test('addBudgetDraft ignores text', () async {
    final s = await app.addBudgetDraft(sample(budgetDraft: 'lots'));
    expect(s.trips[0].days[0].food, 40);
  });
}

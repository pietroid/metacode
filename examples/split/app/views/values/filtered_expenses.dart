// filteredExpenses: visibleExpenses: selected group, filters, newest first.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/visible_expenses.dart';
import '../../models/sample.dart';

List<Expense> filteredExpenses(State state) => visibleExpenses(state);

void main() {
  test('filteredExpenses', () {
    final e = app.filteredExpenses(sample());
    expect(e.length, 3);
    expect(e.first.id, 'e3');
    expect(app.filteredExpenses(sample({'filterCategory': 'food'})).length, 1);
  });
}

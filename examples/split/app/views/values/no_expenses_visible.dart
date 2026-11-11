// noExpensesVisible: true when no expense passes the current filters.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_expenses.dart';

bool noExpensesVisible(State state) {
  final xs = visibleExpenses(state);
  return xs.isEmpty;
}

void main() {
  test('noExpensesVisible', () {
    expect(app.noExpensesVisible(sample()), false);
    expect(app.noExpensesVisible(sample({'filterMember': 'Nobody'})), true);
  });
}

// expenseAmountText: USD amount of filtered expense index, formatted.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_usd.dart';
import 'shared/visible_expenses.dart';

String expenseAmountText(State state, int index) {
  final xs = visibleExpenses(state);
  if (index < 0 || index >= xs.length) return '';
  return formatUsd(xs[index].amount);
}

void main() {
  test('expenseAmountText', () {
    expect(app.expenseAmountText(sample(), 0), '\$50.34');
    expect(app.expenseAmountText(sample(), 9), '');
  });
}

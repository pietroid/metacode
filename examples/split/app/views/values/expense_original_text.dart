// expenseOriginalText: original amount with currency code when not USD, else ''.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_expenses.dart';

String expenseOriginalText(State state, int index) {
  final xs = visibleExpenses(state);
  if (index < 0 || index >= xs.length) return '';
  final e = xs[index];
  if (e.currency == Currency.eur) return '${e.originalAmount.toStringAsFixed(2)} EUR';
  if (e.currency == Currency.brl) return '${e.originalAmount.toStringAsFixed(2)} BRL';
  return '';
}

void main() {
  test('expenseOriginalText', () {
    expect(app.expenseOriginalText(sample(), 0), '45.00 EUR');
    expect(app.expenseOriginalText(sample(), 1), '');
  });
}

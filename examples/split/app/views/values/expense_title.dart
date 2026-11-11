// expenseTitle: description of filtered expense index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_expenses.dart';

String expenseTitle(State state, int index) {
  final xs = visibleExpenses(state);
  if (index < 0 || index >= xs.length) return '';
  return xs[index].description;
}

void main() {
  test('expenseTitle', () {
    expect(app.expenseTitle(sample(), 0), 'Tram 28 tickets');
    expect(app.expenseTitle(sample(), 99), '');
  });
}

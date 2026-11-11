// expenseIcon: icon name per category of filtered expense index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_expenses.dart';

String expenseIcon(State state, int index) {
  final xs = visibleExpenses(state);
  if (index < 0 || index >= xs.length) return 'receipt';
  final c = xs[index].category;
  if (c == Category.food) return 'restaurant';
  if (c == Category.travel) return 'flight';
  if (c == Category.home) return 'home';
  return 'receipt';
}

void main() {
  test('expenseIcon', () {
    expect(app.expenseIcon(sample(), 0), 'flight');
    expect(app.expenseIcon(sample(), 2), 'restaurant');
  });
}

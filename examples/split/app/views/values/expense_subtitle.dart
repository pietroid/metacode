// expenseSubtitle: '<paidBy> <paid> · <category label>' for filtered expense
// index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_expenses.dart';

String expenseSubtitle(State state, Labels labels, int index) {
  final xs = visibleExpenses(state);
  if (index < 0 || index >= xs.length) return '';
  final e = xs[index];
  String cat = labels.other;
  if (e.category == Category.food) cat = labels.food;
  if (e.category == Category.travel) cat = labels.travel;
  if (e.category == Category.home) cat = labels.home;
  return '${e.paidBy} ${labels.paid} · $cat';
}

void main() {
  test('expenseSubtitle', () {
    expect(app.expenseSubtitle(sample(), 0), 'Carla paid · Travel');
    expect(app.expenseSubtitle(sample(), 2), 'Ana paid · Food');
  });
}

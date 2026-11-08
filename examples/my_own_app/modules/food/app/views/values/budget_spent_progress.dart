// budgetSpentProgress: The share of the monthly budget spent (0 to 1).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/spent_usd.dart';

double budgetSpentProgress(State state) {
  if (state.budget <= 0) return 0.0;
  final p = spentUsd(state) / state.budget;
  return p > 1 ? 1.0 : p.toDouble();
}

void main() {
  test('budgetSpentProgress', () async {
    expect(app.budgetSpentProgress(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true, bought: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false, bought: false)])), closeTo(0.1, 0.001));
  });
}

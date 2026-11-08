// budgetSpent: What the bought shopping items (after Shopping done) cost, of the monthly budget.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/money.dart';
import 'shared/spent_usd.dart';

String budgetSpent(State state, Labels labels) => '${money(spentUsd(state), labels)} ${labels.of} ${money(state.budget, labels)}';

void main() {
  test('budgetSpent', () async {
    expect(app.budgetSpent(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true, bought: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false, bought: false)])), r'$30.00 of $300');
  });
}

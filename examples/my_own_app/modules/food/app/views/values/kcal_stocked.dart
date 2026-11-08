// kcalStocked: The kcal of the bought shopping items (after Shopping done), of what the planned days need.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/group_digits.dart';
import 'shared/kcal_target.dart';
import 'shared/stocked_kcal.dart';

String kcalStocked(State state, Labels labels) => '${groupDigits(stockedKcal(state), labels.thousandsSep)} ${labels.of} ${groupDigits(kcalTarget(state), labels.thousandsSep)} ${labels.kcal}';

void main() {
  final items = [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true, bought: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false, bought: false)];
  test('kcalStocked', () async {
    expect(app.kcalStocked(sample().copyWith(shopping: items)), '600 of 800 kcal');
    // Lighter Days: 1,600 kcal a day, 2 days planned.
    expect(app.kcalStocked(sample(goal: Goal.weightLoss, program: 8).copyWith(shopping: items, days: 2)), '600 of 3,200 kcal');
  });
}

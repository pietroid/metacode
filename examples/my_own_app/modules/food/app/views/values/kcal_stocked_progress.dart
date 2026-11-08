// kcalStockedProgress: The share of the planned days' kcal already bought (0 to 1).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/kcal_target.dart';
import 'shared/stocked_kcal.dart';

double kcalStockedProgress(State state) {
  final total = kcalTarget(state);
  if (total <= 0) return 0.0;
  final p = stockedKcal(state) / total;
  if (p > 1) return 1.0;
  return p.toDouble();
}

void main() {
  test('kcalStockedProgress', () async {
    expect(app.kcalStockedProgress(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true, bought: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false, bought: false)])), closeTo(0.75, 0.001));
  });
}

// kcalStockedProgress: The share of the list kcal already in the cart (0 to 1).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/list_kcal.dart';
import 'shared/stocked_kcal.dart';

double kcalStockedProgress(State state) {
  final total = listKcal(state);
  if (total <= 0) return 0.0;
  return (stockedKcal(state) / total).toDouble();
}

void main() {
  test('kcalStockedProgress', () async {
    expect(app.kcalStockedProgress(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false)])), closeTo(0.75, 0.001));
  });
}

// linePrice: the price of a cart line - (item price + size delta (small
// -0.50, medium 0, large +0.70) + 0.70 for oat or almond + 0.80 per shot) x
// quantity; non-customizable items are price x quantity. The item is found by
// id in the menu.

import 'package:flutter_test/flutter_test.dart';
import '../../../../.generated/state.dart';
import '../../../models/sample.dart';

num linePrice(List<MenuItem> menu, CartLine line) {
  num total = 0;
  for (final MenuItem m in menu) {
    if (m.id == line.itemId) {
      num unit = m.price;
      if (m.customizable) {
        if (line.size == DrinkSize.small) unit = unit - 0.5;
        if (line.size == DrinkSize.large) unit = unit + 0.7;
        if (line.milk == Milk.oat || line.milk == Milk.almond) unit = unit + 0.7;
        unit = unit + 0.8 * line.shots;
      }
      total = unit * line.quantity;
    }
  }
  return total;
}

void main() {
  test('linePrice', () {
    final s = sample();
    expect(linePrice(s.menu, s.cart[0]), closeTo(6.7, 0.001));
    expect(linePrice(s.menu, s.cart[1]), closeTo(7.0, 0.001));
  });
}

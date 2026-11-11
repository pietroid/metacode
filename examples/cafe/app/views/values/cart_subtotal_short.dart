// cartSubtotalShort: cart subtotal via formatMoney.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/line_price.dart';
import 'shared/format_money.dart';

String cartSubtotalShort(State state) {
  num total = 0;
  for (final CartLine l in state.cart) {
    total += linePrice(state.menu, l);
  }
  return formatMoney(total);
}

void main() {
  test('initial', () {
    expect(app.cartSubtotalShort(sample()), '\$13.70');
  });
}

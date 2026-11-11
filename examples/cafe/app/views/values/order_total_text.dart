// orderTotalText: Selected order total via formatMoney.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_money.dart';

String orderTotalText(State state) {
  return formatMoney(state.orders[state.selectedOrder.toInt()].total);
}

void main() {
  test('initial', () {
    expect(app.orderTotalText(sample()), '\$8.00');
  });
}

// orderLineTotal: Selected order line index price via formatMoney.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_money.dart';
import 'shared/line_price.dart';

String orderLineTotal(State state, int index) {
  return formatMoney(linePrice(state.menu, state.orders[state.selectedOrder.toInt()].lines[index]));
}

void main() {
  test('index 0', () {
    expect(app.orderLineTotal(sample(), 0), '\$4.75');
  });
}

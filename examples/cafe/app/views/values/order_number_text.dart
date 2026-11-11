// orderNumberText: 'Order #1042' for the selected order.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String orderNumberText(State state, Labels labels) {
  return '${labels.orderTitle} #${state.orders[state.selectedOrder.toInt()].number.toInt()}';
}

void main() {
  test('initial', () {
    expect(app.orderNumberText(sample()), 'Order #1042');
  });
}

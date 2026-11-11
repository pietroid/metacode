// orderPlacedText: placedAt of the selected order.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String orderPlacedText(State state) {
  final int o = state.selectedOrder.toInt();
  if (o < 0 || o >= state.orders.length) return '';
  return state.orders[o].placedAt;
}

void main() {
  test('orderPlacedText', () {
    expect(app.orderPlacedText(sample()), 'Nov 10, 8:42 AM');
  });
  test('orderPlacedText out of range', () {
    expect(app.orderPlacedText(sample({'selectedOrder': 5})), '');
  });
}

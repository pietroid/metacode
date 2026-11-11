// orderPickupText: pickup label of the selected order.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String orderPickupText(State state, Labels labels) {
  final int o = state.selectedOrder.toInt();
  if (o < 0 || o >= state.orders.length) return '';
  final PickupTime p = state.orders[o].pickup;
  if (p == PickupTime.now) return labels.pickupNow;
  if (p == PickupTime.in15) return labels.pickupIn15;
  return labels.pickupIn30;
}

void main() {
  test('orderPickupText', () {
    expect(app.orderPickupText(sample()), 'As soon as possible');
  });
  test('orderPickupText in15', () {
    expect(app.orderPickupText(sample({'selectedOrder': 1})), 'In 15 minutes');
  });
}

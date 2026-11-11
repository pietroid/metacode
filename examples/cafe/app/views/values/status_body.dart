// statusBody: Body for the selected order status.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String statusBody(State state, Labels labels) {
  final OrderStatus s = state.orders[state.selectedOrder.toInt()].status;
  if (s == OrderStatus.placed) return labels.statusPlacedBody;
  if (s == OrderStatus.preparing) return labels.statusPreparingBody;
  return labels.statusReadyBody;
}

void main() {
  test('initial', () {
    expect(app.statusBody(sample()), 'Grab it at the pickup counter. Enjoy!');
  });
}

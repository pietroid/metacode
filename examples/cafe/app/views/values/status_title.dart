// statusTitle: Title for the selected order status.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String statusTitle(State state, Labels labels) {
  final OrderStatus s = state.orders[state.selectedOrder.toInt()].status;
  if (s == OrderStatus.placed) return labels.statusPlaced;
  if (s == OrderStatus.preparing) return labels.statusPreparing;
  return labels.statusReady;
}

void main() {
  test('initial', () {
    expect(app.statusTitle(sample()), 'Ready for pickup');
  });
}

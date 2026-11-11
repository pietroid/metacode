// statusIcon: receipt, timer, checkCircle by selected order status.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String statusIcon(State state) {
  final OrderStatus s = state.orders[state.selectedOrder.toInt()].status;
  if (s == OrderStatus.placed) return 'receipt';
  if (s == OrderStatus.preparing) return 'timer';
  return 'checkCircle';
}

void main() {
  test('initial', () {
    expect(app.statusIcon(sample()), 'checkCircle');
  });
}

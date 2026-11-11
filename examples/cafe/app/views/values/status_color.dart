// statusColor: accent, warning, success by selected order status. @Animated.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated()
String statusColor(State state) {
  final OrderStatus s = state.orders[state.selectedOrder.toInt()].status;
  if (s == OrderStatus.placed) return 'accent';
  if (s == OrderStatus.preparing) return 'warning';
  return 'success';
}

void main() {
  test('initial', () {
    expect(app.statusColor(sample()), 'success');
  });
}

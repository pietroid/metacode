// orderProgress: placed 0.15, preparing 0.55, ready 1.0. @Animated(ms: 600).

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 600)
num orderProgress(State state) {
  final OrderStatus s = state.orders[state.selectedOrder.toInt()].status;
  if (s == OrderStatus.placed) return 0.15;
  if (s == OrderStatus.preparing) return 0.55;
  return 1.0;
}

void main() {
  test('initial', () {
    expect(app.orderProgress(sample()), 1.0);
  });
}

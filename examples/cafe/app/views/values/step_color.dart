// stepColor: primary when step index is reached by the selected order, else fillStrong. @Animated.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated()
String stepColor(State state, int index) {
  final OrderStatus s = state.orders[state.selectedOrder.toInt()].status;
  var reached = 0;
  if (s == OrderStatus.preparing) reached = 1;
  if (s == OrderStatus.ready) reached = 2;
  if (index <= reached) return 'primary';
  return 'fillStrong';
}

void main() {
  test('initial', () {
    expect(app.stepColor(sample(), 2), 'primary');
  });
  test('placed', () {
    final s = sample();
    s.orders[0].status = OrderStatus.placed;
    expect(app.stepColor(s, 1), 'fillStrong');
  });
}

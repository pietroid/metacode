// historyStatusColor: color name of order index status: accent, warning or success.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String historyStatusColor(State state, int index) {
  if (index < 0 || index >= state.orders.length) return 'accent';
  final OrderStatus s = state.orders[index].status;
  if (s == OrderStatus.placed) return 'accent';
  if (s == OrderStatus.preparing) return 'warning';
  return 'success';
}

void main() {
  test('historyStatusColor', () {
    expect(app.historyStatusColor(sample(), 0), 'success');
  });
  test('historyStatusColor placed', () {
    final s = sample();
    s.orders[0].status = OrderStatus.placed;
    expect(app.historyStatusColor(s, 0), 'accent');
  });
}

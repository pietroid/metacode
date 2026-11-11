// historyStatus: status label of order index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String historyStatus(State state, Labels labels, int index) {
  if (index < 0 || index >= state.orders.length) return '';
  final OrderStatus s = state.orders[index].status;
  if (s == OrderStatus.placed) return labels.statusPlaced;
  if (s == OrderStatus.preparing) return labels.statusPreparing;
  return labels.statusReady;
}

void main() {
  test('historyStatus', () {
    expect(app.historyStatus(sample(), 0), 'Ready for pickup');
  });
  test('historyStatus preparing', () {
    final s = sample();
    s.orders[0].status = OrderStatus.preparing;
    expect(app.historyStatus(s, 0), 'Preparing');
  });
}

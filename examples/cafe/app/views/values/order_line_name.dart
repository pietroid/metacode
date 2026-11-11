// orderLineName: '1 × Flat White' for selected order line index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String orderLineName(State state, int index) {
  final CartLine l = state.orders[state.selectedOrder.toInt()].lines[index];
  var name = '';
  for (final MenuItem m in state.menu) {
    if (m.id == l.itemId) name = m.name;
  }
  return '${l.quantity.toInt()} × $name';
}

void main() {
  test('index 0', () {
    expect(app.orderLineName(sample(), 0), '1 × Flat White');
  });
}

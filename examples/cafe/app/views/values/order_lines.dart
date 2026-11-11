// orderLines: Selected order lines.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<CartLine> orderLines(State state) {
  return state.orders[state.selectedOrder.toInt()].lines;
}

void main() {
  test('initial', () {
    expect(app.orderLines(sample()).length, 2);
  });
}

// orderSteps: The three order statuses.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<OrderStatus> orderSteps(State state) {
  return [OrderStatus.placed, OrderStatus.preparing, OrderStatus.ready];
}

void main() {
  test('3', () {
    expect(app.orderSteps(sample()).length, 3);
  });
}

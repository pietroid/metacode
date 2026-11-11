// orderHistory: the orders, newest first as stored.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Order> orderHistory(State state) => state.orders;

void main() {
  test('orderHistory', () {
    expect(app.orderHistory(sample()).length, 2);
  });
  test('orderHistory empty', () {
    expect(app.orderHistory(sample({'orders': []})).length, 0);
  });
}

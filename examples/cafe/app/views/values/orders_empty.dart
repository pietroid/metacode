// ordersEmpty: whether there are no orders.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool ordersEmpty(State state) => state.orders.isEmpty;

void main() {
  test('ordersEmpty', () {
    expect(app.ordersEmpty(sample()), false);
  });
  test('ordersEmpty none', () {
    expect(app.ordersEmpty(sample({'orders': []})), true);
  });
}

// cartIsEmpty: cart is empty.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool cartIsEmpty(State state) => state.cart.isEmpty;

void main() {
  test('initial', () {
    expect(app.cartIsEmpty(sample()), false);
  });
  test('empty', () {
    expect(app.cartIsEmpty(sample({'cart': []})), true);
  });
}

// cartHasItems: cart is not empty.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool cartHasItems(State state) => state.cart.isNotEmpty;

void main() {
  test('initial', () {
    expect(app.cartHasItems(sample()), true);
  });
}

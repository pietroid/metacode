// cartLines: The cart lines.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<CartLine> cartLines(State state) {
  return state.cart;
}

void main() {
  test('initial', () {
    expect(app.cartLines(sample()).length, 2);
  });
}

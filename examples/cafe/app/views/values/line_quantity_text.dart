// lineQuantityText: Cart line index quantity as text.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String lineQuantityText(State state, int index) {
  return '${state.cart[index].quantity.toInt()}';
}

void main() {
  test('index 1', () {
    expect(app.lineQuantityText(sample(), 1), '2');
  });
}

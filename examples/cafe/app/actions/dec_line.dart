// decLine: cart line index quantity - 1; at 1 the line is removed.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> decLine(State state, void Function(StateDelta) emit, int index) async {
  final cart = state.cart;
  if (index < 0 || index >= cart.length) return;
  if (cart[index].quantity.toInt() <= 1) {
    cart.removeAt(index);
  } else {
    cart[index] = cart[index].copyWith(quantity: cart[index].quantity - 1);
  }
  emit(StateDelta(cart: cart));
}

void main() {
  test('decLine decrements', () async {
    final s = await app.decLine(sample(), 1);
    expect(s.cart[1].quantity, 1);
  });
  test('decLine removes at 1', () async {
    final s = await app.decLine(sample(), 0);
    expect(s.cart.length, 1);
    expect(s.cart[0].itemId, 'croissant');
  });
}

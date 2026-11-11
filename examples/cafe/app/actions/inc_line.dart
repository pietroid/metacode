// incLine: cart line index quantity + 1.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> incLine(State state, void Function(StateDelta) emit, int index) async {
  final cart = state.cart;
  if (index < 0 || index >= cart.length) return;
  cart[index] = cart[index].copyWith(quantity: cart[index].quantity + 1);
  emit(StateDelta(cart: cart));
}

void main() {
  test('incLine', () async {
    final s = await app.incLine(sample(), 0);
    expect(s.cart[0].quantity, 2);
  });
}

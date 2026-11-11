// removeLine: removes cart line index.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> removeLine(State state, void Function(StateDelta) emit, int index) async {
  final cart = state.cart;
  if (index < 0 || index >= cart.length) return;
  cart.removeAt(index);
  emit(StateDelta(cart: cart));
}

void main() {
  test('removeLine', () async {
    final s = await app.removeLine(sample(), 0);
    expect(s.cart.length, 1);
  });
}

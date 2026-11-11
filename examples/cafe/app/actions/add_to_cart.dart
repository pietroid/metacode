// addToCart: adds the draft as a cart line for the selected item (merging
// quantity into an identical line) and pops the item page.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> addToCart(State state, void Function(StateDelta) emit, Core core) async {
  final MenuItem item = state.menu[state.selectedItem.toInt()];
  final cart = state.cart;
  var merged = false;
  for (var i = 0; i < cart.length; i++) {
    final CartLine l = cart[i];
    if (!merged &&
        l.itemId == item.id &&
        l.size == state.draftSize &&
        l.milk == state.draftMilk &&
        l.shots == state.draftShots) {
      cart[i] = l.copyWith(quantity: l.quantity + state.draftQuantity);
      merged = true;
    }
  }
  if (!merged) {
    cart.add(CartLine(
      itemId: item.id,
      size: state.draftSize,
      milk: state.draftMilk,
      shots: state.draftShots,
      quantity: state.draftQuantity,
    ));
  }
  emit(StateDelta(cart: cart));
  await core.navigator.pop();
}

void main() {
  test('addToCart adds a new line', () async {
    final s = await app.addToCart(sample({'selectedItem': 1}));
    expect(s.cart.length, 3);
    expect(s.cart[2].itemId, 'cappuccino');
    expect(app.navigation, ['pop']);
  });
  test('addToCart merges an identical line', () async {
    final s = await app.addToCart(sample({
      'selectedItem': 0,
      'draftSize': 'large',
      'draftMilk': 'oat',
      'draftShots': 1,
      'draftQuantity': 2,
    }));
    expect(s.cart.length, 2);
    expect(s.cart[0].quantity, 3);
  });
}

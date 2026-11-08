// shoppingStatus: How much of the shopping list is in the cart.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String shoppingStatus(State state, Labels labels) {
  var done = 0;
  for (final i in state.shopping) {
    if (i.checked) done++;
  }
  return '$done ${labels.of} ${state.shopping.length} ${labels.inCart}';
}

void main() {
  test('shoppingStatus', () async {
    final s = sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 1, kcal: 1, count: 1, checked: true, bought: true), Item(name: 'B', namePt: 'B', qty: '1', price: 1, kcal: 1, count: 1, checked: false, bought: false)]);
    expect(app.shoppingStatus(s), '1 of 2 in the cart');
  });
}

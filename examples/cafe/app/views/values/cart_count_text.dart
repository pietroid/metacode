// cartCountText: total quantity with item/items label - '3 items'.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String cartCountText(State state, Labels labels) {
  num total = 0;
  for (final CartLine l in state.cart) {
    total += l.quantity;
  }
  final String word = total == 1 ? labels.item : labels.items;
  return '${total.toInt()} $word';
}

void main() {
  test('initial', () {
    expect(app.cartCountText(sample()), '3 items');
  });
}

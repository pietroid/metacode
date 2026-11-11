// addToCartText: Add to cart label and the draft line price.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_money.dart';
import 'shared/line_price.dart';

String addToCartText(State state, Labels labels) {
  final CartLine draft = CartLine(
    itemId: state.menu[state.selectedItem.toInt()].id,
    size: state.draftSize,
    milk: state.draftMilk,
    shots: state.draftShots,
    quantity: state.draftQuantity,
  );
  return '${labels.addToCartLabel} · ${formatMoney(linePrice(state.menu, draft))}';
}

void main() {
  test('initial', () {
    expect(app.addToCartText(sample()), 'Add to cart · \$4.50');
  });
}

// itemPriceText: Visible item index price via formatMoney.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'visible_items.dart';
import 'shared/format_money.dart';

String itemPriceText(State state, int index) {
  final List<MenuItem> items = visibleItems(state);
  return formatMoney(items[index].price);
}

void main() {
  test('index 0', () {
    expect(app.itemPriceText(sample(), 0), '\$4.50');
  });
}

// selectedPriceText: selected item base price via formatMoney.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_money.dart';

String selectedPriceText(State state) {
  final MenuItem m = state.menu[state.selectedItem.toInt()];
  return formatMoney(m.price);
}

void main() {
  test('initial', () {
    expect(app.selectedPriceText(sample()), '\$4.50');
  });
}

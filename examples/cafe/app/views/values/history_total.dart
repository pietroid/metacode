// historyTotal: total of order index, formatted as money.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_money.dart';

String historyTotal(State state, int index) {
  if (index < 0 || index >= state.orders.length) return '';
  return formatMoney(state.orders[index].total);
}

void main() {
  test('historyTotal', () {
    expect(app.historyTotal(sample(), 1), '\$13.50');
  });
  test('historyTotal out of range', () {
    expect(app.historyTotal(sample(), 5), '');
  });
}

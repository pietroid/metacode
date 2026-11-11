// historyTitle: title of order index, like Order #1042.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String historyTitle(State state, Labels labels, int index) {
  if (index < 0 || index >= state.orders.length) return '';
  return '${labels.orderTitle} #${state.orders[index].number.toInt()}';
}

void main() {
  test('historyTitle', () {
    expect(app.historyTitle(sample(), 1), 'Order #1038');
  });
  test('historyTitle out of range', () {
    expect(app.historyTitle(sample(), 5), '');
  });
}

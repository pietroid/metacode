// shopTotal: The whole list's cost.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/money.dart';

String shopTotal(State state, Labels labels) {
  num t = 0;
  for (final i in state.shopping) {
    t += i.price;
  }
  return '${labels.total} ${money(t, labels)}';
}

void main() {
  test('shopTotal', () async {
    expect(app.shopTotal(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false)])), r'Total $40.00');
  });
}

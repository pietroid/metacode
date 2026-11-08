// itemQty: A shopping line's quantity, times how many recipes use it.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String itemQty(State state, int index) {
  final i = state.shopping[index];
  return i.count > 1 ? '${i.qty} ×${i.count}' : i.qty;
}

void main() {
  test('itemQty', () async {
    expect(app.itemQty(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false)]), 0), '1');
  });
}

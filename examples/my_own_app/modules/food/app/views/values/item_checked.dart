// itemChecked: Whether a shopping line is in the cart.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool itemChecked(State state, int index) => state.shopping[index].checked;

void main() {
  test('itemChecked', () async {
    expect(app.itemChecked(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false)]), 1), false);
  });
}

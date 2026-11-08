// itemPrice: A shopping line's price.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/money.dart';

String itemPrice(State state, Labels labels, int index) => money(state.shopping[index].price, labels);

void main() {
  test('itemPrice', () async {
    expect(app.itemPrice(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true, bought: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false, bought: false)]), 0), r'$30.00');
  });
}

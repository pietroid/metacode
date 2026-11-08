// shopList: The shopping list lines.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Item> shopList(State state) => state.shopping;

void main() {
  test('shopList', () async {
    expect(app.shopList(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false)])).length, 2);
  });
}

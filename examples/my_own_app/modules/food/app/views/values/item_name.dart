// itemName: A shopping line's ingredient name.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/pick.dart';

String itemName(State state, Labels labels, int index) => pick(labels, state.shopping[index].name, state.shopping[index].namePt);

void main() {
  test('itemName', () async {
    expect(app.itemName(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false)]), 0), 'A');
  });
}

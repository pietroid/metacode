// toggleItem: Checks or unchecks a shopping line (in the cart).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> toggleItem(State state, void Function(StateDelta) emit, int index, bool value) async {
  state.shopping[index].checked = value;
  emit(StateDelta(shopping: state.shopping));
}

void main() {
  test('toggleItem', () async {
    expect((await app.toggleItem(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false)]), 1, true)).shopping[1].checked, true);
  });
}

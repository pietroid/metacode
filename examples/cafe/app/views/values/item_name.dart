// itemName: Visible item index name.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'visible_items.dart';

String itemName(State state, int index) {
  final List<MenuItem> items = visibleItems(state);
  return items[index].name;
}

void main() {
  test('index 0', () {
    expect(app.itemName(sample(), 0), 'Caffè Latte');
  });
}

// itemIcon: Visible item index icon.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'visible_items.dart';

String itemIcon(State state, int index) {
  final List<MenuItem> items = visibleItems(state);
  return items[index].icon;
}

void main() {
  test('index 0', () {
    expect(app.itemIcon(sample(), 0), 'drop');
  });
}

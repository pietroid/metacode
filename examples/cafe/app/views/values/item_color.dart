// itemColor: Visible item index color.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'visible_items.dart';

String itemColor(State state, int index) {
  final List<MenuItem> items = visibleItems(state);
  return items[index].color;
}

void main() {
  test('index 0', () {
    expect(app.itemColor(sample(), 0), '#C89F7A');
  });
}

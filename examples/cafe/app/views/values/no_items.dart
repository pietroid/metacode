// noItems: visibleItems is empty.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'visible_items.dart';

bool noItems(State state) {
  final List<MenuItem> items = visibleItems(state);
  return items.isEmpty;
}

void main() {
  test('zzz', () {
    expect(app.noItems(sample({'search': 'zzz'})), true);
  });
  test('initial', () {
    expect(app.noItems(sample()), false);
  });
}

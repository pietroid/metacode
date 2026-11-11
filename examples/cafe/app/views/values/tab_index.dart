// tabIndex: currentTab index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

num tabIndex(State state) {
  if (state.currentTab == Tab.rewards) return 1;
  if (state.currentTab == Tab.orders) return 2;
  if (state.currentTab == Tab.profile) return 3;
  return 0;
}

void main() {
  test('initial', () {
    expect(app.tabIndex(sample()), 0);
  });
  test('orders', () {
    expect(app.tabIndex(sample({'currentTab': 'orders'})), 2);
  });
}

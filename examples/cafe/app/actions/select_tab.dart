// selectTab: sets currentTab to the tab at index.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> selectTab(State state, void Function(StateDelta) emit, int index) async {
  const tabs = <Tab>[Tab.menu, Tab.rewards, Tab.orders, Tab.profile];
  if (index < 0 || index >= tabs.length) return;
  emit(StateDelta(currentTab: tabs[index]));
}

void main() {
  test('selectTab', () async {
    final s = await app.selectTab(sample(), 2);
    expect(s.currentTab, Tab.orders);
  });
}

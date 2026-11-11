// goToMenu: sets currentTab menu and pops the order page.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> goToMenu(State state, void Function(StateDelta) emit, Core core) async {
  emit(StateDelta(currentTab: Tab.menu));
  await core.navigator.pop();
}

void main() {
  test('goToMenu', () async {
    final s = await app.goToMenu(sample({'currentTab': 'orders'}));
    expect(s.currentTab, Tab.menu);
    expect(app.navigation.last, 'pop');
  });
}

// transfersVisible: the selected group has recorded transfers.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool transfersVisible(State state) {
  for (final Transfer t in state.transfers) {
    if (t.groupId == state.selectedGroup) return true;
  }
  return false;
}

void main() {
  test('transfersVisible', () {
    expect(app.transfersVisible(sample()), true);
    expect(app.transfersVisible(sample({'selectedGroup': 'g2'})), false);
  });
}

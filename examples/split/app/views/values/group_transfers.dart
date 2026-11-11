// groupTransfers: the selected group's transfers, newest first.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Transfer> groupTransfers(State state) {
  final all = state.transfers;
  final List<Transfer> out = [];
  for (int i = all.length - 1; i >= 0; i--) {
    if (all[i].groupId == state.selectedGroup) out.add(all[i]);
  }
  return out;
}

void main() {
  test('groupTransfers', () {
    final xs = app.groupTransfers(sample());
    expect(xs.length, 1);
    final ys = app.groupTransfers(sample({'selectedGroup': 'g2'}));
    expect(ys.length, 0);
  });
}

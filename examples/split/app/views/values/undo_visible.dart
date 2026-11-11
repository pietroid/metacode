// undoVisible: True when lastDeleted's first expense belongs to the selected group.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool undoVisible(State state) {
  final List<Expense> d = state.lastDeleted;
  if (d.isEmpty) return false;
  return d[0].groupId == state.selectedGroup;
}

void main() {
  test('undoVisible', () {
    expect(app.undoVisible(sample()), false);
    final s = sample();
    s.lastDeleted = [s.expenses[0]];
    expect(app.undoVisible(s), true);
  });
}

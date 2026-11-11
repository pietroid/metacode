// deleteExpenseAt: Takes filteredExpenses' item index (via visibleExpenses),
// calls remote.deleteExpense with its id. Success -> lastDeleted is [it] (a
// list of 0 or 1), syncError ''. Error -> syncError errorOffline.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/labels.dart';
import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/visible_expenses.dart';

Future<void> deleteExpenseAt(State state, void Function(StateDelta) emit, Remote remote, Labels labels, int index) async {
  final List<Expense> visible = visibleExpenses(state);
  if (index < 0 || index >= visible.length) return;
  final Expense it = visible[index];
  final error = await remote.deleteExpense(it.id);
  if (error != null) {
    emit(StateDelta(syncError: labels.errorOffline));
  } else {
    emit(StateDelta(lastDeleted: [it], syncError: ''));
  }
}

void main() {
  test('deleteExpenseAt remembers the deleted expense', () async {
    final s = await app.deleteExpenseAt(sample(), 0);
    expect(s.lastDeleted.length, 1);
    expect(s.lastDeleted[0].id, 'e3');
    expect(s.syncError, '');
  });
}

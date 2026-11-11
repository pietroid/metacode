// addExpense: Appends the expense to shared expenses (replacing one with the
// same id). Refuses (no change) amount <= 0, empty owed, or an unknown
// groupId.

import '../../../.generated/remote_state.dart';

Future<void> addExpense(State state, void Function(StateDelta) emit, Expense value) async {
  if (value.amount <= 0) throw RemoteError('amount');
  if (value.owed.isEmpty) throw RemoteError('owed');
  var known = false;
  for (final Group g in state.groups) {
    if (g.id == value.groupId) known = true;
  }
  if (!known) throw RemoteError('group');
  final List<Expense> list = [];
  for (final Expense e in state.expenses) {
    if (e.id != value.id) list.add(e);
  }
  list.add(value);
  emit(StateDelta(expenses: list));
}

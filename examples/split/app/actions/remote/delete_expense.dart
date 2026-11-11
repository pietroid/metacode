// deleteExpense: Removes the expense with this id from shared expenses; no
// change when missing.

import '../../../.generated/remote_state.dart';

Future<void> deleteExpense(State state, void Function(StateDelta) emit, String value) async {
  final List<Expense> list = [];
  var found = false;
  for (final Expense e in state.expenses) {
    if (e.id == value) {
      found = true;
    } else {
      list.add(e);
    }
  }
  if (found) emit(StateDelta(expenses: list));
}

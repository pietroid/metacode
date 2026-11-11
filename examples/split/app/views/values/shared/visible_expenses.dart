// visibleExpenses: Expenses of the selected group, filtered by filterMember
// (paid by or owes a share) and filterCategory, newest first (reverse list
// order).

import '../../../../.generated/state.dart';

List<Expense> visibleExpenses(State state) {
  final List<Expense> out = [];
  final List<Expense> all = state.expenses;
  for (var i = all.length - 1; i >= 0; i--) {
    final Expense e = all[i];
    var ok = e.groupId == state.selectedGroup;
    if (ok && state.filterMember != '') {
      var involved = e.paidBy == state.filterMember;
      for (final Share s in e.owed) {
        if (s.member == state.filterMember) involved = true;
      }
      ok = involved;
    }
    if (ok && state.filterCategory != '') {
      var match = false;
      if (state.filterCategory == 'food' && e.category == Category.food) match = true;
      if (state.filterCategory == 'travel' && e.category == Category.travel) match = true;
      if (state.filterCategory == 'home' && e.category == Category.home) match = true;
      if (state.filterCategory == 'other' && e.category == Category.other) match = true;
      ok = match;
    }
    if (ok) out.add(e);
  }
  return out;
}

// memberBalances: Balance per member (same order) for group groupId: paid
// expenses minus owed shares, plus transfers sent minus transfers received,
// rounded to cents.

import '../../../../.generated/state.dart';

List<num> memberBalances(State state, String groupId, List<String> members) {
  final List<num> out = [];
  for (final String m in members) {
    double total = 0;
    for (final Expense e in state.expenses) {
      if (e.groupId == groupId) {
        if (e.paidBy == m) total += e.amount.toDouble();
        for (final Share s in e.owed) {
          if (s.member == m) total -= s.amount.toDouble();
        }
      }
    }
    for (final Transfer t in state.transfers) {
      if (t.groupId == groupId) {
        if (t.from == m) total += t.amount.toDouble();
        if (t.to == m) total -= t.amount.toDouble();
      }
    }
    out.add((total * 100).round() / 100);
  }
  return out;
}

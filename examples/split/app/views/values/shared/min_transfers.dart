// minTransfers: Greedy settle-up: repeatedly the largest debtor pays the
// largest creditor the smaller of the two amounts, until all are within half a
// cent. Transfers have id '' and the groupId.

import '../../../../.generated/state.dart';

List<Transfer> minTransfers(String groupId, List<String> members, List<num> balances) {
  final List<double> b = [];
  for (final num x in balances) {
    b.add(x.toDouble());
  }
  final List<Transfer> out = [];
  var guard = 0;
  while (guard < 200) {
    guard++;
    var di = -1;
    var ci = -1;
    for (var i = 0; i < b.length; i++) {
      if (b[i] < -0.005 && (di < 0 || b[i] < b[di])) di = i;
      if (b[i] > 0.005 && (ci < 0 || b[i] > b[ci])) ci = i;
    }
    if (di < 0 || ci < 0) break;
    final double debt = -b[di];
    final double credit = b[ci];
    final double raw = debt < credit ? debt : credit;
    final double a = ((raw * 100).round() / 100).toDouble();
    out.add(Transfer(id: '', groupId: groupId, from: members[di], to: members[ci], amount: a));
    b[di] = b[di] + raw;
    b[ci] = b[ci] - raw;
  }
  return out;
}

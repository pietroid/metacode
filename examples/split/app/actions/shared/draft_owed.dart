// draftOwed: Shares owed (USD, rounded to cents, last chosen member takes the
// rounding remainder) for totalUsd from the draft: equal among draftChosen
// members; shares by the parsed draftShares weights (members with weight > 0);
// exact from draftExact times state.rate (members with amount > 0).

import '../../../.generated/state.dart';
import '../../views/values/shared/current_group.dart';
import '../../views/values/shared/parse_amount.dart';

List<Share> draftOwed(State state, num totalUsd) {
  final List<String> members = currentGroup(state).members;
  final List<Share> out = [];
  if (state.draftMode == SplitMode.exact) {
    for (var i = 0; i < members.length; i++) {
      final num raw = i < state.draftExact.length ? parseAmount(state.draftExact[i]) : 0;
      if (raw > 0) {
        out.add(Share(member: members[i], amount: (raw * state.rate * 100).round() / 100));
      }
    }
    return out;
  }
  final List<double> w = [];
  double sum = 0;
  for (var i = 0; i < members.length; i++) {
    double x = 0;
    if (state.draftMode == SplitMode.equal) {
      if (i < state.draftChosen.length && state.draftChosen[i]) x = 1;
    } else {
      if (i < state.draftShares.length) x = parseAmount(state.draftShares[i]).toDouble();
    }
    w.add(x);
    sum += x;
  }
  if (sum <= 0) return out;
  var last = -1;
  for (var i = 0; i < w.length; i++) {
    if (w[i] > 0) last = i;
  }
  double given = 0;
  for (var i = 0; i < w.length; i++) {
    if (w[i] > 0) {
      double amt = ((totalUsd * w[i] / sum) * 100).round() / 100;
      if (i == last) amt = ((totalUsd - given) * 100).round() / 100;
      given += amt;
      out.add(Share(member: members[i], amount: amt));
    }
  }
  return out;
}

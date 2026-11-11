// validateDraft: The first error text or '': errorRate unless rateStatus ready,
// errorAmount unless parseAmount(draftAmount) > 0, errorNoMembers when no
// member is chosen (equal) or has a share/amount > 0, errorExactSum when exact
// amounts differ from the amount by more than half a cent.

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../views/values/shared/parse_amount.dart';

String validateDraft(State state, Labels labels) {
  if (state.rateStatus != RateStatus.ready) return labels.errorRate;
  final double amount = parseAmount(state.draftAmount).toDouble();
  if (amount <= 0) return labels.errorAmount;
  var any = false;
  double exactSum = 0;
  if (state.draftMode == SplitMode.equal) {
    for (final bool c in state.draftChosen) {
      if (c) any = true;
    }
  } else if (state.draftMode == SplitMode.shares) {
    for (final String s in state.draftShares) {
      if (parseAmount(s) > 0) any = true;
    }
  } else {
    for (final String s in state.draftExact) {
      final double v = parseAmount(s).toDouble();
      if (v > 0) any = true;
      exactSum += v;
    }
  }
  if (!any) return labels.errorNoMembers;
  if (state.draftMode == SplitMode.exact) {
    final double diff = exactSum - amount;
    if (diff > 0.005 || diff < -0.005) return labels.errorExactSum;
  }
  return '';
}

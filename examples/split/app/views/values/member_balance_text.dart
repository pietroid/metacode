// memberBalanceText: Member index's balance signed: +$254.66, −$140.00 (U+2212) or $0.00.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/format_usd.dart';
import 'shared/member_balances.dart';
import '../../models/sample.dart';

String memberBalanceText(State state, int index) {
  final Group g = currentGroup(state);
  final List<num> b = memberBalances(state, g.id, g.members);
  final num v = b[index];
  if (v > 0.005) return '+${formatUsd(v)}';
  if (v < -0.005) return '−${formatUsd(v)}';
  return formatUsd(0);
}

void main() {
  test('memberBalanceText', () {
    expect(app.memberBalanceText(sample(), 1), '+\$254.66');
    expect(app.memberBalanceText(sample(), 0), '−\$140.00');
  });
}

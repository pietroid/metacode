// draftMemberOwesText: what member index would owe in USD, '' when nothing.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../actions/shared/draft_owed.dart';
import '../../models/sample.dart';
import 'shared/current_group.dart';
import 'shared/format_usd.dart';
import 'shared/parse_amount.dart';

String draftMemberOwesText(State state, int index) {
  final members = currentGroup(state).members;
  if (index < 0 || index >= members.length) return '';
  final num amount = parseAmount(state.draftAmount);
  if (amount <= 0) return '';
  final owed = draftOwed(state, amount * state.rate);
  for (final Share s in owed) {
    if (s.member == members[index] && s.amount > 0) return formatUsd(s.amount);
  }
  return '';
}

void main() {
  test('draftMemberOwesText', () {
    final s = sample({'draftAmount': '84'});
    expect(app.draftMemberOwesText(s, 0), '\$21.00');
    expect(app.draftMemberOwesText(sample(), 0), '');
  });
}

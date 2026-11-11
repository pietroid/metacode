// openAddExpense: Resets the draft for the selected group (description and
// amount empty, usd, other, mode equal, paidBy = me via myMember, draftChosen
// all true, draftShares all '1', draftExact all '' sized to the members, rate
// 1, rateStatus ready, formError '', saveStatus idle) and pushes the
// addExpense route.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/current_group.dart';
import '../views/values/shared/my_member.dart';

Future<void> openAddExpense(State state, void Function(StateDelta) emit, Core core) async {
  final Group g = currentGroup(state);
  final List<bool> chosen = [];
  final List<String> shares = [];
  final List<String> exact = [];
  for (var i = 0; i < g.members.length; i++) {
    chosen.add(true);
    shares.add('1');
    exact.add('');
  }
  emit(StateDelta(
    draftDescription: '',
    draftAmount: '',
    draftCurrency: Currency.usd,
    draftCategory: Category.other,
    draftMode: SplitMode.equal,
    draftPaidBy: myMember(state, g.id),
    draftChosen: chosen,
    draftShares: shares,
    draftExact: exact,
    rate: 1,
    rateStatus: RateStatus.ready,
    formError: '',
    saveStatus: SaveStatus.idle,
  ));
  core.navigator.push(Routes.addExpense);
}

void main() {
  test('openAddExpense resets the draft', () async {
    final s = await app.openAddExpense(sample({'selectedGroup': 'g2'}));
    expect(s.draftChosen, [true, true, true]);
    expect(s.draftPaidBy, 'Ana');
    expect(app.navigation, ['push addExpense']);
  });
}

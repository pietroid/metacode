// saveExpense: Validates with validateDraft (error -> formError, stop). Else
// builds the Expense (id 'e' + millisecondsSinceEpoch, groupId selectedGroup,
// description or defaultDescription, amount = original * rate rounded to
// cents, owed from draftOwed), sets saveStatus saving, calls
// remote.addExpense. Error -> saveStatus failed, formError errorOffline,
// sheet stays. Success -> saveStatus idle and pop.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/labels.dart';
import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/parse_amount.dart';
import 'shared/draft_owed.dart';
import 'shared/validate_draft.dart';

Future<void> saveExpense(State state, void Function(StateDelta) emit, Core core, Remote remote, Labels labels) async {
  final String err = validateDraft(state, labels);
  if (err != '') {
    emit(StateDelta(formError: err));
    return;
  }
  final double original = parseAmount(state.draftAmount).toDouble();
  final double amount = ((original * state.rate * 100).round() / 100).toDouble();
  final String desc = state.draftDescription.trim();
  final Expense expense = Expense(
    id: 'e${DateTime.now().millisecondsSinceEpoch}',
    groupId: state.selectedGroup,
    description: desc == '' ? labels.defaultDescription : desc,
    amount: amount,
    originalAmount: original,
    currency: state.draftCurrency,
    category: state.draftCategory,
    paidBy: state.draftPaidBy,
    splitMode: state.draftMode,
    owed: draftOwed(state, amount),
  );
  emit(StateDelta(saveStatus: SaveStatus.saving, formError: ''));
  final error = await remote.addExpense(expense);
  if (error != null) {
    emit(StateDelta(saveStatus: SaveStatus.failed, formError: labels.errorOffline));
  } else {
    emit(StateDelta(saveStatus: SaveStatus.idle));
    await core.navigator.pop();
  }
}

void main() {
  test('saveExpense validates the amount', () async {
    final s = await app.saveExpense(sample());
    expect(s.formError, 'Enter an amount greater than 0.');
    expect(app.navigation, []);
  });
  test('saveExpense saves and pops', () async {
    final s = await app.saveExpense(sample({'draftAmount': '30'}));
    expect(s.saveStatus, SaveStatus.idle);
    expect(app.remoteCalls, ['addExpense']);
    expect(app.navigation, ['pop']);
  });
}

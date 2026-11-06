import 'package:flutter_test/flutter_test.dart';

import '../generated/state.dart';
import 'fixtures.dart';

void main() {
  test('state.yaml loads and is usable', () {
    expect(app.entryList(app.initialState), isA<List<Entry>>());
    expect(app.pageTitle(app.initialState), isA<String>());
  });

  test('navigation bindings', () {
    expect(app.pageIndex(sample(page: Page.goals)), 1);
    expect(app.pageTitle(sample(page: Page.menu)), 'Menu');
    expect(app.currentPage(sample(page: Page.goals)), 'goals');
  });

  test('totals', () {
    expect(app.balanceValue(sample()), 600);
    expect(app.balanceText(sample()), '\$600.00');
    expect(app.incomeText(sample()), '\$1000.00');
    expect(app.expenseText(sample()), '\$400.00');
    expect(app.balanceText(app.resetData(sample())), '\$0.00');
  });

  test('entry item bindings are newest first', () {
    final s = sample();
    expect(app.entryTitleAt(s, 0), 'Rent');
    expect(app.entryAmountAt(s, 0), '-\$400.00');
    expect(app.entryAmountAt(s, 1), '+\$1000.00');
    expect(app.entryIsIncome(s, 1), true);
    expect(app.entryDateAt(s, 0), '2026-11-02');
  });

  test('kind flags', () {
    expect(app.kindIsExpense(sample()), true);
    expect(app.kindIsIncome(sample(entryKind: EntryKind.income)), true);
  });

  test('goal item bindings', () {
    final s = sample();
    expect(app.goalNameAt(s, 0), 'Trip');
    expect(app.goalAmountsAt(s, 0), '\$50.00 of \$200.00');
    expect(app.goalProgressAt(s, 0), 0.25);
    expect(app.goalPercentAt(s, 0), '25%');
    expect(app.goalReachedAt(s, 0), false);
    expect(app.goalReachedAt(s, 1), true);
    expect(app.contributionLabel(s), 'Add \$50.00');
    expect(app.goalCountText(s), '1 of 2 reached');
  });

  test('profile bindings', () {
    final s = sample();
    expect(app.profileInitials(s), 'AL');
    expect(app.profileName(s), 'Ada Lovelace');
    expect(app.profileCurrency(app.updateCurrency(s, '€')), '€');
    expect(app.currencyOptions(s), contains('€'));
    expect(app.notificationsOn(s), true);
    expect(app.entryCountText(s), '2');
  });

  test('draft values', () {
    expect(app.entryTitleValue(sample(entryTitle: 'a')), 'a');
    expect(app.entryAmountValue(sample(entryAmount: '1')), '1');
    expect(app.goalNameValue(sample(goalName: 'g')), 'g');
    expect(app.goalTargetValue(sample(goalTarget: '9')), '9');
    expect(app.contributionValue(sample()), '50');
  });
}

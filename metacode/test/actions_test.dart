import 'package:flutter_test/flutter_test.dart';

import '../generated/state.dart';
import 'fixtures.dart';

void main() {
  test('goToPage switches tabs', () {
    expect(app.goToPage(sample(), 1).page, Page.goals);
    expect(app.goToPage(sample(), 2).page, Page.menu);
    expect(app.goToPage(sample(page: Page.menu), 0).page, Page.finances);
  });

  test('entry draft inputs', () {
    expect(app.updateEntryTitle(sample(), 'Coffee').entryTitle, 'Coffee');
    expect(app.updateEntryAmount(sample(), '3.5').entryAmount, '3.5');
    expect(app.selectIncome(sample()).entryKind, EntryKind.income);
    expect(app.selectExpense(sample(entryKind: EntryKind.income)).entryKind, EntryKind.expense);
  });

  test('addEntry appends and clears the draft', () {
    final next = app.addEntry(sample(entryTitle: 'Coffee', entryAmount: '3,5'));
    expect(next.entries.length, 3);
    expect(next.entries.last.title, 'Coffee');
    expect(next.entries.last.amount, 3.5);
    expect(next.entries.last.kind, EntryKind.expense);
    expect(next.entryTitle, '');
    expect(next.entryAmount, '');
  });

  test('addEntry ignores invalid input', () {
    expect(app.addEntry(sample(entryTitle: 'X', entryAmount: 'abc')).entries.length, 2);
    expect(app.addEntry(sample(entryAmount: '10')).entries.length, 2);
    expect(app.addEntry(sample(entryTitle: 'X', entryAmount: '-5')).entries.length, 2);
  });

  test('deleteEntry uses newest-first index', () {
    final next = app.deleteEntry(sample(), 0);
    expect(next.entries.map((e) => e.title), ['Salary']);
  });

  test('goal inputs and addGoal', () {
    expect(app.updateGoalName(sample(), 'Car').goalName, 'Car');
    expect(app.updateGoalTarget(sample(), '900').goalTarget, '900');
    expect(app.updateContribution(sample(), '20').contribution, '20');
    final next = app.addGoal(sample(goalName: 'Car', goalTarget: '900'));
    expect(next.goals.last.name, 'Car');
    expect(next.goals.last.target, 900);
    expect(next.goals.last.saved, 0);
    expect(next.goalName, '');
    expect(app.addGoal(sample(goalName: 'Car')).goals.length, 2);
  });

  test('contributeToGoal adds the contribution', () {
    expect(app.contributeToGoal(sample(contribution: '25'), 0).goals[0].saved, 75);
    expect(app.contributeToGoal(sample(contribution: 'x'), 0).goals[0].saved, 50);
  });

  test('deleteGoal', () {
    expect(app.deleteGoal(sample(), 0).goals.map((g) => g.name), ['Bike']);
  });

  test('profile actions', () {
    expect(app.updateProfileName(sample(), 'Bob').profile.name, 'Bob');
    expect(app.updateProfileEmail(sample(), 'b@x.io').profile.email, 'b@x.io');
    expect(app.updateCurrency(sample(), '€').profile.currency, '€');
    expect(app.toggleNotifications(sample(), false).profile.notifications, false);
  });

  test('resetData clears entries and goals', () {
    final next = app.resetData(sample());
    expect(next.entries, isEmpty);
    expect(next.goals, isEmpty);
    expect(next.profile.name, 'Ada Lovelace');
  });
}

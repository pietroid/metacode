import 'package:flutter_test/flutter_test.dart';

import '../generated/core.dart';
import '../generated/state.dart';
import 'fixtures.dart';

void main() {
  test('goToPage switches tabs', () async {
    expect((await app.goToPage(sample(), 1)).page, Page.goals);
    expect((await app.goToPage(sample(), 2)).page, Page.menu);
    expect((await app.goToPage(sample(page: Page.menu), 0)).page, Page.finances);
  });

  test('actions emit only what changes', () async {
    await app.updateEntryTitle(sample(), 'Coffee');
    expect(app.emitted, [
      {'entryTitle': 'Coffee'},
    ]);
  });

  test('entry draft inputs', () async {
    expect((await app.updateEntryTitle(sample(), 'Coffee')).entryTitle, 'Coffee');
    expect((await app.updateEntryAmount(sample(), '3.5')).entryAmount, '3.5');
    expect((await app.selectIncome(sample())).entryKind, EntryKind.income);
    expect((await app.selectExpense(sample(entryKind: EntryKind.income))).entryKind,
        EntryKind.expense);
  });

  test('addEntry appends and clears the draft', () async {
    final next = await app.addEntry(sample(entryTitle: 'Coffee', entryAmount: '3,5'));
    expect(next.entries.length, 3);
    expect(next.entries.last.title, 'Coffee');
    expect(next.entries.last.amount, 3.5);
    expect(next.entries.last.kind, EntryKind.expense);
    expect(next.entryTitle, '');
    expect(next.entryAmount, '');
  });

  test('addEntry ignores invalid input', () async {
    expect((await app.addEntry(sample(entryTitle: 'X', entryAmount: 'abc'))).entries.length, 2);
    expect(app.emitted, isEmpty);
    expect((await app.addEntry(sample(entryAmount: '10'))).entries.length, 2);
    expect((await app.addEntry(sample(entryTitle: 'X', entryAmount: '-5'))).entries.length, 2);
  });

  test('deleteEntry uses newest-first index', () async {
    final next = await app.deleteEntry(sample(), 0);
    expect(next.entries.map((e) => e.title), ['Salary']);
  });

  test('goal inputs and addGoal', () async {
    expect((await app.updateGoalName(sample(), 'Car')).goalName, 'Car');
    expect((await app.updateGoalTarget(sample(), '900')).goalTarget, '900');
    expect((await app.updateContribution(sample(), '20')).contribution, '20');
    final next = await app.addGoal(sample(goalName: 'Car', goalTarget: '900'));
    expect(next.goals.last.name, 'Car');
    expect(next.goals.last.target, 900);
    expect(next.goals.last.saved, 0);
    expect(next.goalName, '');
    expect((await app.addGoal(sample(goalName: 'Car'))).goals.length, 2);
  });

  test('contributeToGoal adds the contribution', () async {
    expect((await app.contributeToGoal(sample(contribution: '25'), 0)).goals[0].saved, 75);
    expect((await app.contributeToGoal(sample(contribution: 'x'), 0)).goals[0].saved, 50);
  });

  test('deleteGoal', () async {
    expect((await app.deleteGoal(sample(), 0)).goals.map((g) => g.name), ['Bike']);
  });

  test('profile actions', () async {
    expect((await app.updateProfileName(sample(), 'Bob')).profile.name, 'Bob');
    expect((await app.updateProfileEmail(sample(), 'b@x.io')).profile.email, 'b@x.io');
    expect((await app.updateCurrency(sample(), '€')).profile.currency, '€');
    expect((await app.toggleNotifications(sample(), false)).profile.notifications, false);
  });

  test('askResetData opens the confirmation dialog', () async {
    final next = await app.askResetData(sample());
    expect(app.navigation, ['push confirmReset']);
    expect(next.entries.length, 2);
  });

  test('resetData clears entries and goals and closes the dialog', () async {
    final next = await app.resetData(sample());
    expect(next.entries, isEmpty);
    expect(next.goals, isEmpty);
    expect(next.profile.name, 'Ada Lovelace');
    expect(app.navigation, ['pop']);
  });

  group('dollar rate', () {
    tearDown(() => app.api = (m, u, b) => ApiResponse(status: 404, body: ''));

    test('fetchDollarRate shows loading, then the rate', () async {
      app.api = (method, url, body) => ApiResponse(
            status: 200,
            body: '{"result":"success","time_last_update_utc":"Fri, 06 Nov 2026",'
                '"rates":{"USD":1,"BRL":5.4321}}',
          );
      final next = await app.fetchDollarRate(sample());
      expect(app.requests, ['GET https://open.er-api.com/v6/latest/USD']);
      expect(app.emitted.first, {'dollarRateStatus': 'loading'});
      expect(next.dollarRateStatus, FetchStatus.loaded);
      expect(next.dollarRate, 5.4321);
      expect(next.dollarRateUpdated, 'Fri, 06 Nov 2026');
    });

    test('fetchDollarRate fails on errors', () async {
      expect((await app.fetchDollarRate(sample())).dollarRateStatus, FetchStatus.failed);
      app.api = (m, u, b) => ApiResponse(status: 200, body: '{"rates":{}}');
      expect((await app.fetchDollarRate(sample())).dollarRateStatus, FetchStatus.failed);
    });

    test('openDollarRate opens the sheet and loads', () async {
      await app.openDollarRate(sample());
      expect(app.navigation, ['push dollarRate']);
      expect(app.requests.length, 1);
    });
  });
}

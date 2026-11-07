import '../generated/state.dart';
import '../generated/test_app.dart';

/// Runs actions and bindings through the compiled program, like the engine.
final app = TestApp();

/// A small state to start tests from.
State sample({
  Page page = Page.finances,
  String entryTitle = '',
  String entryAmount = '',
  EntryKind entryKind = EntryKind.expense,
  String goalName = '',
  String goalTarget = '',
  String contribution = '50',
}) =>
    State(
      page: page,
      entries: [
        Entry(title: 'Salary', amount: 1000, kind: EntryKind.income, date: DateTime(2026, 11, 1)),
        Entry(title: 'Rent', amount: 400, kind: EntryKind.expense, date: DateTime(2026, 11, 2)),
      ],
      goals: [
        Goal(name: 'Trip', target: 200, saved: 50),
        Goal(name: 'Bike', target: 100, saved: 100),
      ],
      profile: Profile(name: 'Ada Lovelace', email: 'ada@example.com', currency: '\$', notifications: true),
      entryTitle: entryTitle,
      entryAmount: entryAmount,
      entryKind: entryKind,
      goalName: goalName,
      goalTarget: goalTarget,
      contribution: contribution,
      dollarRate: 0,
      dollarRateStatus: FetchStatus.idle,
      dollarRateUpdated: '',
    );

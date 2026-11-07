// Actions react to the UI. Each one receives the current [State] plus, by
// name: `emit` (apply a StateDelta), `core` (api + navigator), `index`
// inside list items and `value` from inputs.
//
// Change the state only with emit(StateDelta(...)): set just the fields that
// change; the rest stay as they are. Emit as often as needed (e.g. loading,
// then the result). [state] is a fresh copy taken when the action starts, so
// changing it in place and emitting the changed field is fine.

import '../generated/core.dart';
import '../generated/state.dart';
import '../bindings/bindings.dart';

num? _parseAmount(String text) {
  final n = num.tryParse(text.trim().replaceAll(',', '.'));
  if (n == null || n <= 0) return null;
  return n;
}

// Navigation

Future<void> goToPage(State state, void Function(StateDelta) emit, int value) async {
  if (value == 1) return emit(StateDelta(page: Page.goals));
  if (value == 2) return emit(StateDelta(page: Page.menu));
  emit(StateDelta(page: Page.finances));
}

/// Closes the sheet or dialog on top.
Future<void> close(State state, Core core) async {
  await core.navigator.pop();
}

// Finances

Future<void> updateEntryTitle(State state, void Function(StateDelta) emit, String value) async =>
    emit(StateDelta(entryTitle: value));

Future<void> updateEntryAmount(State state, void Function(StateDelta) emit, String value) async =>
    emit(StateDelta(entryAmount: value));

Future<void> selectIncome(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(entryKind: EntryKind.income));

Future<void> selectExpense(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(entryKind: EntryKind.expense));

Future<void> addEntry(State state, void Function(StateDelta) emit) async {
  final amount = _parseAmount(state.entryAmount);
  final title = state.entryTitle.trim();
  if (amount == null || title.isEmpty) return;
  state.entries.add(Entry(
    title: title,
    amount: amount,
    kind: state.entryKind,
    date: DateTime.now(),
  ));
  emit(StateDelta(entries: state.entries, entryTitle: '', entryAmount: ''));
}

Future<void> deleteEntry(State state, void Function(StateDelta) emit, int index) async {
  state.entries.remove(entryList(state)[index]);
  emit(StateDelta(entries: state.entries));
}

// Goals

Future<void> updateGoalName(State state, void Function(StateDelta) emit, String value) async =>
    emit(StateDelta(goalName: value));

Future<void> updateGoalTarget(State state, void Function(StateDelta) emit, String value) async =>
    emit(StateDelta(goalTarget: value));

Future<void> updateContribution(State state, void Function(StateDelta) emit, String value) async =>
    emit(StateDelta(contribution: value));

Future<void> addGoal(State state, void Function(StateDelta) emit) async {
  final target = _parseAmount(state.goalTarget);
  final name = state.goalName.trim();
  if (target == null || name.isEmpty) return;
  state.goals.add(Goal(name: name, target: target, saved: 0));
  emit(StateDelta(goals: state.goals, goalName: '', goalTarget: ''));
}

Future<void> contributeToGoal(State state, void Function(StateDelta) emit, int index) async {
  final amount = _parseAmount(state.contribution);
  if (amount == null) return;
  final goal = state.goals[index];
  goal.saved = goal.saved + amount;
  emit(StateDelta(goals: state.goals));
}

Future<void> deleteGoal(State state, void Function(StateDelta) emit, int index) async {
  state.goals.removeAt(index);
  emit(StateDelta(goals: state.goals));
}

// Menu

Future<void> updateProfileName(State state, void Function(StateDelta) emit, String value) async {
  state.profile.name = value;
  emit(StateDelta(profile: state.profile));
}

Future<void> updateProfileEmail(State state, void Function(StateDelta) emit, String value) async {
  state.profile.email = value;
  emit(StateDelta(profile: state.profile));
}

Future<void> updateCurrency(State state, void Function(StateDelta) emit, String value) async {
  state.profile.currency = value;
  emit(StateDelta(profile: state.profile));
}

Future<void> toggleNotifications(State state, void Function(StateDelta) emit, bool value) async {
  state.profile.notifications = value;
  emit(StateDelta(profile: state.profile));
}

/// Asks first: opens the confirmReset dialog.
Future<void> askResetData(State state, Core core) async {
  await core.navigator.push(Routes.confirmReset);
}

Future<void> resetData(State state, void Function(StateDelta) emit, Core core) async {
  emit(StateDelta(entries: [], goals: []));
  await core.navigator.pop();
}

// Dollar rate

const _dollarRateUrl = 'https://open.er-api.com/v6/latest/USD';

/// Opens the dollar rate sheet and loads a fresh rate.
Future<void> openDollarRate(State state, void Function(StateDelta) emit, Core core) async {
  core.navigator.push(Routes.dollarRate);
  await fetchDollarRate(state, emit, core);
}

/// Reads USD -> BRL from a free api (no key needed).
Future<void> fetchDollarRate(State state, void Function(StateDelta) emit, Core core) async {
  emit(StateDelta(dollarRateStatus: FetchStatus.loading));
  final response = await core.api.get(_dollarRateUrl);
  if (!response.ok) {
    emit(StateDelta(dollarRateStatus: FetchStatus.failed));
    return;
  }
  final json = response.json as Map;
  final rate = (json['rates'] as Map)['BRL'];
  if (rate is! num) {
    emit(StateDelta(dollarRateStatus: FetchStatus.failed));
    return;
  }
  emit(StateDelta(
    dollarRate: rate,
    dollarRateStatus: FetchStatus.loaded,
    dollarRateUpdated: (json['time_last_update_utc'] ?? '') as String,
  ));
}

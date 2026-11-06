// Actions are transfer functions: NextState = action(CurrentState).
//
// Each action receives the current [State] (plus event params matched by name:
// `index` inside list items, `value` from inputs) and returns the next state.
// The state is a fresh copy, so changing it in place and returning it is fine;
// `copyWith` is there when you prefer building a new one.

import '../generated/state.dart';
import '../bindings/bindings.dart';

num? _parseAmount(String text) {
  final n = num.tryParse(text.trim().replaceAll(',', '.'));
  if (n == null || n <= 0) return null;
  return n;
}

// Navigation

State goToPage(State state, int value) {
  if (value == 1) return state.copyWith(page: Page.goals);
  if (value == 2) return state.copyWith(page: Page.menu);
  return state.copyWith(page: Page.finances);
}

// Finances

State updateEntryTitle(State state, String value) => state.copyWith(entryTitle: value);

State updateEntryAmount(State state, String value) => state.copyWith(entryAmount: value);

State selectIncome(State state) => state.copyWith(entryKind: EntryKind.income);

State selectExpense(State state) => state.copyWith(entryKind: EntryKind.expense);

State addEntry(State state) {
  final amount = _parseAmount(state.entryAmount);
  final title = state.entryTitle.trim();
  if (amount == null || title.isEmpty) return state;
  state.entries.add(Entry(
    title: title,
    amount: amount,
    kind: state.entryKind,
    date: DateTime.now(),
  ));
  return state.copyWith(entryTitle: '', entryAmount: '');
}

State deleteEntry(State state, int index) {
  state.entries.remove(entryList(state)[index]);
  return state;
}

// Goals

State updateGoalName(State state, String value) => state.copyWith(goalName: value);

State updateGoalTarget(State state, String value) => state.copyWith(goalTarget: value);

State updateContribution(State state, String value) => state.copyWith(contribution: value);

State addGoal(State state) {
  final target = _parseAmount(state.goalTarget);
  final name = state.goalName.trim();
  if (target == null || name.isEmpty) return state;
  state.goals.add(Goal(name: name, target: target, saved: 0));
  return state.copyWith(goalName: '', goalTarget: '');
}

State contributeToGoal(State state, int index) {
  final amount = _parseAmount(state.contribution);
  if (amount == null) return state;
  final goal = state.goals[index];
  goal.saved = goal.saved + amount;
  return state;
}

State deleteGoal(State state, int index) {
  state.goals.removeAt(index);
  return state;
}

// Menu

State updateProfileName(State state, String value) {
  state.profile.name = value;
  return state;
}

State updateProfileEmail(State state, String value) {
  state.profile.email = value;
  return state;
}

State updateCurrency(State state, String value) {
  state.profile.currency = value;
  return state;
}

State toggleNotifications(State state, bool value) {
  state.profile.notifications = value;
  return state;
}

State resetData(State state) {
  state.entries.clear();
  state.goals.clear();
  return state;
}

// Bindings read the state for the UI. Each one receives the current [State]
// (plus `index` when used inside a list item) and returns a value.

import '../generated/state.dart';

String _money(State state, num value) {
  final sign = value < 0 ? '-' : '';
  return '$sign${state.profile.currency}${value.abs().toStringAsFixed(2)}';
}

num _sumOf(State state, EntryKind kind) {
  num total = 0;
  for (final Entry e in state.entries) {
    if (e.kind == kind) total += e.amount;
  }
  return total;
}

// Navigation

int pageIndex(State state) {
  if (state.page == Page.goals) return 1;
  if (state.page == Page.menu) return 2;
  return 0;
}

String pageTitle(State state) {
  if (state.page == Page.goals) return 'Goals';
  if (state.page == Page.menu) return 'Menu';
  return 'Finances';
}

String currentPage(State state) {
  if (state.page == Page.goals) return 'goals';
  if (state.page == Page.menu) return 'menu';
  return 'finances';
}

// Finances

num balanceValue(State state) =>
    _sumOf(state, EntryKind.income) - _sumOf(state, EntryKind.expense);

String balanceText(State state) => _money(state, balanceValue(state));

String incomeText(State state) => _money(state, _sumOf(state, EntryKind.income));

String expenseText(State state) => _money(state, _sumOf(state, EntryKind.expense));

List<Entry> entryList(State state) => state.entries.reversed.toList();

Entry _entryAt(State state, int index) => entryList(state)[index];

String entryTitleAt(State state, int index) => _entryAt(state, index).title;

String entryDateAt(State state, int index) =>
    _entryAt(state, index).date.toIso8601String().substring(0, 10);

String entryAmountAt(State state, int index) {
  final e = _entryAt(state, index);
  final text = _money(state, e.amount);
  return e.kind == EntryKind.income ? '+$text' : '-$text';
}

bool entryIsIncome(State state, int index) =>
    _entryAt(state, index).kind == EntryKind.income;

String entryTitleValue(State state) => state.entryTitle;

String entryAmountValue(State state) => state.entryAmount;

bool kindIsIncome(State state) => state.entryKind == EntryKind.income;

bool kindIsExpense(State state) => state.entryKind == EntryKind.expense;

// Goals

List<Goal> goalList(State state) => state.goals;

String goalNameAt(State state, int index) => state.goals[index].name;

String goalAmountsAt(State state, int index) {
  final g = state.goals[index];
  return '${_money(state, g.saved)} of ${_money(state, g.target)}';
}

double goalProgressAt(State state, int index) {
  final g = state.goals[index];
  if (g.target <= 0) return 0;
  final p = g.saved / g.target;
  return p > 1 ? 1.0 : p.toDouble();
}

String goalPercentAt(State state, int index) =>
    '${(goalProgressAt(state, index) * 100).round()}%';

bool goalReachedAt(State state, int index) {
  final g = state.goals[index];
  return g.saved >= g.target;
}

String goalNameValue(State state) => state.goalName;

String goalTargetValue(State state) => state.goalTarget;

String contributionValue(State state) => state.contribution;

String contributionLabel(State state) {
  final amount = num.tryParse(state.contribution) ?? 0;
  return 'Add ${_money(state, amount)}';
}

// Menu

String profileName(State state) => state.profile.name;

String profileEmail(State state) => state.profile.email;

String profileInitials(State state) {
  final parts = state.profile.name.trim().split(' ');
  var initials = '';
  for (final String p in parts) {
    if (p.isNotEmpty && initials.length < 2) initials += p.substring(0, 1).toUpperCase();
  }
  return initials.isEmpty ? '?' : initials;
}

String profileCurrency(State state) => state.profile.currency;

List<String> currencyOptions(State state) => ['\$', '€', '£', 'R\$', '¥'];

bool notificationsOn(State state) => state.profile.notifications;

String entryCountText(State state) => '${state.entries.length}';

String goalCountText(State state) {
  final reached = state.goals.where((Goal g) => g.saved >= g.target).length;
  return '$reached of ${state.goals.length} reached';
}

// Actions react to the UI. Each one receives the current [State] plus, by
// name: `emit` (apply a StateDelta), `core` (api + navigator), `index`
// inside list items and `value` from inputs.

import '../generated/core.dart';
import '../generated/state.dart';
import '../bindings/bindings.dart';

// Make my app (the demo in the hero)

/// How long each build step shows before the next one.
const int buildStepMs = 700;

/// Walks the four build steps, then shows "Your app is ready".
Future<void> makeApp(State state, void Function(StateDelta) emit) async {
  if (state.buildStep >= 1 && state.buildStep <= 4) return;
  await _runBuild(emit);
}

Future<void> _runBuild(void Function(StateDelta) emit) async {
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: buildStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

Future<void> updateIdea(State state, void Function(StateDelta) emit, String value) async =>
    emit(StateDelta(idea: value, buildStep: 0));

Future<void> _pickIdea(State state, void Function(StateDelta) emit, String idea) async {
  if (state.buildStep >= 1 && state.buildStep <= 4) return;
  emit(StateDelta(idea: idea));
  await _runBuild(emit);
}

Future<void> pickHabits(State state, void Function(StateDelta) emit) async =>
    _pickIdea(state, emit, 'Track my daily habits');

Future<void> pickMeals(State state, void Function(StateDelta) emit) async =>
    _pickIdea(state, emit, 'Plan meals for the week');

Future<void> pickBills(State state, void Function(StateDelta) emit) async =>
    _pickIdea(state, emit, 'Split bills with roommates');

Future<void> pickBooks(State state, void Function(StateDelta) emit) async =>
    _pickIdea(state, emit, 'Keep my book list');

// Waitlist

/// Opens the waitlist sheet.
Future<void> openWaitlist(State state, Core core) async {
  core.navigator.push(Routes.waitlist);
}

Future<void> updateEmail(State state, void Function(StateDelta) emit, String value) async {
  if (state.waitlistStatus == WaitlistStatus.invalid) {
    return emit(StateDelta(email: value, waitlistStatus: WaitlistStatus.idle));
  }
  emit(StateDelta(email: value));
}

bool _looksLikeEmail(String text) {
  final t = text.trim();
  final at = t.indexOf('@');
  return at > 0 && t.lastIndexOf('.') > at + 1 && !t.endsWith('.') && !t.contains(' ');
}

Future<void> joinWaitlist(State state, void Function(StateDelta) emit) async {
  if (state.waitlistStatus == WaitlistStatus.joined) return;
  if (!_looksLikeEmail(state.email)) {
    return emit(StateDelta(waitlistStatus: WaitlistStatus.invalid));
  }
  emit(StateDelta(
    email: state.email.trim(),
    waitlistStatus: WaitlistStatus.joined,
    waitlistCount: state.waitlistCount + 1,
  ));
}

/// Closes the sheet on top.
Future<void> close(State state, Core core) async {
  await core.navigator.pop();
}

// Example apps carousel

const int exampleCount = 4;

Future<void> nextExample(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: (state.exampleIndex + 1) % exampleCount));

Future<void> previousExample(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: (state.exampleIndex + exampleCount - 1) % exampleCount));

Future<void> showFood(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: 0));
Future<void> showMusic(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: 1));
Future<void> showWork(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: 2));
Future<void> showPlants(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: 3));

/// Uses the current example's sentence as the idea and opens the waitlist.
Future<void> makeLikeThis(State state, void Function(StateDelta) emit, Core core) async {
  emit(StateDelta(idea: examplePrompt(state).replaceAll('“', '').replaceAll('”', ''), buildStep: 0));
  core.navigator.push(Routes.waitlist);
}

// Food: log servings

Future<void> addFood(State state, void Function(StateDelta) emit, int index) async {
  state.foods[index].count += 1;
  emit(StateDelta(foods: state.foods));
}

Future<void> removeFood(State state, void Function(StateDelta) emit, int index) async {
  if (state.foods[index].count <= 0) return;
  state.foods[index].count -= 1;
  emit(StateDelta(foods: state.foods));
}

Future<void> clearFoods(State state, void Function(StateDelta) emit) async {
  for (final f in state.foods) {
    f.count = 0;
  }
  emit(StateDelta(foods: state.foods));
}

// Music: chords and practice

Future<void> toggleChord(State state, void Function(StateDelta) emit, int index, bool value) async {
  state.chords[index].learned = value;
  emit(StateDelta(chords: state.chords));
}

Future<void> logPractice(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(practiceMinutes: state.practiceMinutes + 5));

// Work: jobs and taxes

Future<void> toggleJobPaid(State state, void Function(StateDelta) emit, int index, bool value) async {
  state.jobs[index].paid = value;
  emit(StateDelta(jobs: state.jobs));
}

Future<void> setTaxRate(State state, void Function(StateDelta) emit, double value) async =>
    emit(StateDelta(taxRate: value.round()));

// Plants: water and pass the days

Future<void> waterPlant(State state, void Function(StateDelta) emit, int index) async {
  state.plants[index].daysLeft = state.plants[index].everyDays;
  emit(StateDelta(plants: state.plants));
}

Future<void> nextDay(State state, void Function(StateDelta) emit) async {
  for (final p in state.plants) {
    if (p.daysLeft > 0) p.daysLeft -= 1;
  }
  emit(StateDelta(plants: state.plants));
}

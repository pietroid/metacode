// Bindings turn the state into values for the UI.

import '../generated/state.dart';

String ideaValue(State state) => state.idea;

bool ideaIsHabits(State state) => state.idea == 'Track my daily habits';
bool ideaIsMeals(State state) => state.idea == 'Plan meals for the week';
bool ideaIsBills(State state) => state.idea == 'Split bills with roommates';
bool ideaIsBooks(State state) => state.idea == 'Keep my book list';

// Build steps: "todo", "doing" or "done" for each of the four.

String _stepState(State state, int step) {
  if (state.buildStep > step) return 'done';
  if (state.buildStep == step) return 'doing';
  return 'todo';
}

String step1State(State state) => _stepState(state, 1);
String step2State(State state) => _stepState(state, 2);
String step3State(State state) => _stepState(state, 3);
String step4State(State state) => _stepState(state, 4);

bool buildReady(State state) => state.buildStep >= 5;

String makeButtonText(State state) {
  if (state.buildStep >= 1 && state.buildStep <= 4) return 'Making…';
  if (state.buildStep >= 5) return 'Make it again';
  return 'Make my app';
}

// Waitlist

String emailValue(State state) => state.email;

bool waitlistJoined(State state) => state.waitlistStatus == WaitlistStatus.joined;
bool waitlistInvalid(State state) => state.waitlistStatus == WaitlistStatus.invalid;

/// "1,284 people are already on the list".
String waitlistCountText(State state) {
  final digits = state.waitlistCount.round().toString();
  var out = '';
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += ',';
    out += digits[i];
  }
  return '$out people are already on the list';
}

/// The idea shown in the waitlist sheet.
String ideaSummary(State state) {
  final idea = state.idea.trim();
  if (idea.isEmpty) return 'Tell us what you need and we\'ll have your app ready when you get in.';
  return 'Your first app: "$idea". We\'ll have it ready when you get in.';
}

String joinedText(State state) => 'We\'ll email ${state.email} when your spot opens.';

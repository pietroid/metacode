// Relations turn the state into values for the UI.

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
String waitlistCountText(State state) =>
    '${_groupDigits(state.waitlistCount)} people are already on the list';

/// 1234567 -> "1,234,567".
String _groupDigits(num n) {
  final digits = (n < 0 ? 0 - n : n).round().toString();
  var out = n < 0 ? "-" : "";
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += ',';
    out += digits[i];
  }
  return out;
}

/// The idea shown in the waitlist sheet.
String ideaSummary(State state) {
  final idea = state.idea.trim();
  if (idea.isEmpty) return 'Tell us what you need and we\'ll have your app ready when you get in.';
  return 'Your first app: "$idea". We\'ll have it ready when you get in.';
}

String joinedText(State state) => 'We\'ll email ${state.email} when your spot opens.';

// Example apps carousel (the mini apps themselves live in apps/)

String exampleKey(State state) {
  final i = state.exampleIndex.round();
  if (i == 1) return 'music';
  if (i == 2) return 'work';
  if (i == 3) return 'plants';
  return 'food';
}

bool exampleIsFood(State state) => state.exampleIndex.round() == 0;
bool exampleIsMusic(State state) => state.exampleIndex.round() == 1;
bool exampleIsWork(State state) => state.exampleIndex.round() == 2;
bool exampleIsPlants(State state) => state.exampleIndex.round() == 3;

String _examplePromptFor(int i) {
  if (i == 1) return 'Teach me guitar, ten minutes a day';
  if (i == 2) return 'Help me keep track of my freelance jobs';
  if (i == 3) return 'Remind me to water my plants';
  return 'Help me eat better without counting everything';
}

String examplePrompt(State state) => '“${_examplePromptFor(state.exampleIndex.round())}”';

String exampleTag(State state) {
  final i = state.exampleIndex.round();
  if (i == 1) return 'MUSIC';
  if (i == 2) return 'WORK';
  if (i == 3) return 'HOME';
  return 'FOOD';
}

String exampleBlurb(State state) {
  final i = state.exampleIndex.round();
  if (i == 1) return 'One chord at a time. Log your practice and see which songs you can already play.';
  if (i == 2) return 'Who paid, who still owes you, and how much to put aside for taxes. No spreadsheet.';
  if (i == 3) return 'Every plant on its own schedule. Tap the drop when you water it, and skip ahead a day to see what comes next.';
  return 'Tap what you ate. It adds up the calories and suggests what to eat next to stay on track.';
}

String exampleImage(State state) {
  final i = state.exampleIndex.round();
  if (i == 1) return 'metacode/assets/guitar.jpg';
  if (i == 2) return 'metacode/assets/desk.jpg';
  if (i == 3) return 'metacode/assets/plant.jpg';
  return 'metacode/assets/food.jpg';
}

String examplePosition(State state) => '${state.exampleIndex.round() + 1} of 4';

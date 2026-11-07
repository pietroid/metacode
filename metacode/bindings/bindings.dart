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

// Example apps carousel

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

// Food

double _capAtOne(num p) {
  final double d = p.toDouble();
  if (d > 1) return 1.0;
  return d;
}

num _eatenKcal(State state) {
  num total = 0;
  for (final f in state.foods) {
    total += f.kcal * f.count;
  }
  return total;
}

num _eatenProtein(State state) {
  num total = 0;
  for (final f in state.foods) {
    total += f.protein * f.count;
  }
  return total;
}

List<Food> foodList(State state) => state.foods;

String foodName(State state, int index) => state.foods[index].name;
String foodInfo(State state, int index) =>
    '${state.foods[index].kcal.round()} kcal · ${state.foods[index].protein.round()} g protein';
String foodCount(State state, int index) => '${state.foods[index].count.round()}';

String caloriesText(State state) =>
    '${_groupDigits(_eatenKcal(state))} of ${_groupDigits(state.calorieGoal)} kcal';

String proteinText(State state) => '${_eatenProtein(state).round()} g protein today';

double caloriesProgress(State state) {
  if (state.calorieGoal <= 0) return 0.0;
  return _capAtOne(_eatenKcal(state) / state.calorieGoal);
}

String foodTip(State state) {
  final eaten = _eatenKcal(state);
  final protein = _eatenProtein(state);
  final left = state.calorieGoal - eaten;
  if (eaten == 0) return 'Start with breakfast. Oatmeal or eggs keep you full until lunch.';
  if (left < 0) {
    return "You're ${_groupDigits(0 - left)} kcal over today. No stress: a walk after dinner and a lighter lunch tomorrow even it out.";
  }
  if (left < 250) return 'Almost there. Greek yogurt or an apple fits what is left.';
  if (protein < 60) {
    return '${_groupDigits(left)} kcal left, and you are low on protein. A grilled chicken salad would cover both.';
  }
  return 'Good balance so far. ${_groupDigits(left)} kcal left for the rest of the day.';
}

// Music

List<Chord> chordList(State state) => state.chords;

String chordName(State state, int index) => state.chords[index].name;
String chordFingers(State state, int index) => state.chords[index].fingers;
bool chordLearned(State state, int index) => state.chords[index].learned;

int _learnedCount(State state) => state.chords.where((Chord c) => c.learned).length;

String chordsText(State state) => '${_learnedCount(state)} of ${state.chords.length} chords learned';

double chordsProgress(State state) {
  if (state.chords.isEmpty) return 0.0;
  return _capAtOne(_learnedCount(state) / state.chords.length);
}

bool _knows(State state, String name) =>
    state.chords.any((Chord c) => c.name == name && c.learned);

String musicTip(State state) {
  if (_knows(state, 'G') && _knows(state, 'C') && _knows(state, 'D') && _knows(state, 'Em')) {
    if (_learnedCount(state) == state.chords.length) {
      return 'You know all six. Next week: strumming patterns.';
    }
    return 'G, C, D and Em: those four chords play hundreds of pop songs. You can start one today.';
  }
  for (final c in state.chords) {
    if (!c.learned) return 'Next up: ${c.name}. ${c.fingers}.';
  }
  return 'Pick a chord to start.';
}

String practiceText(State state) {
  final m = state.practiceMinutes.round();
  if (m >= 10) return '$m min today. Goal reached';
  return '$m of 10 min today';
}

double practiceProgress(State state) {
  return _capAtOne(state.practiceMinutes / 10);
}

// Work

List<Job> jobList(State state) => state.jobs;

String jobClient(State state, int index) => state.jobs[index].client;
String jobTask(State state, int index) => state.jobs[index].task;
String jobAmount(State state, int index) => '\$${_groupDigits(state.jobs[index].amount)}';
bool jobPaid(State state, int index) => state.jobs[index].paid;

num _received(State state) {
  num total = 0;
  for (final j in state.jobs) {
    if (j.paid) total += j.amount;
  }
  return total;
}

num _waiting(State state) {
  num total = 0;
  for (final j in state.jobs) {
    if (!j.paid) total += j.amount;
  }
  return total;
}

String receivedText(State state) => '\$${_groupDigits(_received(state))}';
String waitingText(State state) => '\$${_groupDigits(_waiting(state))}';

double taxRateValue(State state) => state.taxRate.toDouble();

String taxText(State state) {
  final reserve = _received(state) * state.taxRate / 100;
  return 'Set aside ${state.taxRate.round()}% for taxes: \$${_groupDigits(reserve)}';
}

String workTip(State state) {
  Job? biggest;
  for (final j in state.jobs) {
    if (!j.paid && (biggest == null || j.amount > biggest.amount)) biggest = j;
  }
  if (biggest == null) return 'Everyone paid. Nice month.';
  return '${biggest.client} still owes you \$${_groupDigits(biggest.amount)}. Want me to draft a friendly reminder?';
}

// Plants

List<Plant> plantList(State state) => state.plants;

String plantName(State state, int index) => state.plants[index].name;
String plantSchedule(State state, int index) => 'Every ${state.plants[index].everyDays.round()} days';

String plantStatus(State state, int index) {
  final d = state.plants[index].daysLeft.round();
  if (d <= 0) return 'Water today';
  if (d == 1) return 'Tomorrow';
  return 'In $d days';
}

String plantsText(State state) {
  final n = state.plants.where((Plant p) => p.daysLeft <= 0).length;
  if (n == 0) return 'All watered';
  if (n == 1) return '1 plant needs water today';
  return '$n plants need water today';
}

String plantTip(State state) {
  final thirsty = state.plants.where((Plant p) => p.daysLeft <= 0).map((Plant p) => p.name).toList();
  if (thirsty.isNotEmpty) return 'Water ${thirsty.join(' and ')} today.';
  Plant? next;
  for (final p in state.plants) {
    if (next == null || p.daysLeft < next.daysLeft) next = p;
  }
  if (next == null) return 'Add your first plant.';
  final d = next.daysLeft.round();
  return 'All done. Next up: ${next.name} ${d == 1 ? 'tomorrow' : 'in $d days'}.';
}

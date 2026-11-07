// Relations turn the state into values for the UI.

import '../generated/state.dart';

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

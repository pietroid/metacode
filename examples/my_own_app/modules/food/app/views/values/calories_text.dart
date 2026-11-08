// caloriesText: The formatted calorie count versus the daily goal.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

/// 1234567 -> "1,234,567".
String _caloriesTextGroupDigits(num n) {
  final digits = (n < 0 ? 0 - n : n).round().toString();
  var out = n < 0 ? "-" : "";
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += ',';
    out += digits[i];
  }
  return out;
}

num _caloriesTextEatenKcal(State state) {
  num total = 0;
  for (final f in state.foods) {
    total += f.kcal * f.count;
  }
  return total;
}

String caloriesText(State state) =>
    '${_caloriesTextGroupDigits(_caloriesTextEatenKcal(state))} of ${_caloriesTextGroupDigits(state.calorieGoal)} kcal';

void main() {
  test('caloriesText', () {
    expect(app.caloriesText(app.initialState), '1,495 of 1,800 kcal');
    final oats = sample(
      foods: [Food(name: 'Oats', kcal: 300, protein: 10, count: 1)],
    );
    expect(app.caloriesText(oats), '300 of 1,000 kcal');
  });
}

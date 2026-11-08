// foodTip returns a contextual tip based on calories and protein so far.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String _foodTipGroupDigits(num n) {
  final digits = (n < 0 ? 0 - n : n).round().toString();
  var out = n < 0 ? "-" : "";
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += ',';
    out += digits[i];
  }
  return out;
}

num _foodTipEatenKcal(State state) {
  num total = 0;
  for (final f in state.foods) {
    total += f.kcal * f.count;
  }
  return total;
}

num _foodTipEatenProtein(State state) {
  num total = 0;
  for (final f in state.foods) {
    total += f.protein * f.count;
  }
  return total;
}

String foodTip(State state, Labels labels) {
  final eaten = _foodTipEatenKcal(state);
  final protein = _foodTipEatenProtein(state);
  final left = state.calorieGoal - eaten;
  if (eaten == 0) return labels.tipStart;
  if (left < 0) {
    return '${labels.tipOverBefore} ${_foodTipGroupDigits(0 - left)} ${labels.tipOverAfter}';
  }
  if (left < 250) return labels.tipAlmost;
  if (protein < 60) {
    return '${_foodTipGroupDigits(left)} ${labels.tipLowProtein}';
  }
  return '${labels.tipBalanced} ${_foodTipGroupDigits(left)} ${labels.tipKcalLeftDay}';
}

void main() {
  test('foodTip', () {
    expect(app.foodTip(sample()), contains('breakfast'));
    final oats = sample(
      foods: [Food(name: 'Oats', kcal: 300, protein: 10, count: 1)],
    );
    expect(app.foodTip(oats), contains('low on protein'));
    final over = sample(
      foods: [Food(name: 'Pizza', kcal: 600, protein: 20, count: 2)],
    );
    expect(app.foodTip(over), contains('200 kcal over'));
  });
}

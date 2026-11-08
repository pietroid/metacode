// caloriesProgress: The share of the daily calorie goal already eaten.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

double _caloriesProgressCapAtOne(num p) {
  final double d = p.toDouble();
  if (d > 1) return 1.0;
  return d;
}

num _caloriesProgressEatenKcal(State state) {
  num total = 0;
  for (final f in state.foods) {
    total += f.kcal * f.count;
  }
  return total;
}

double caloriesProgress(State state) {
  if (state.calorieGoal <= 0) return 0.0;
  return _caloriesProgressCapAtOne(
    _caloriesProgressEatenKcal(state) / state.calorieGoal,
  );
}

void main() {
  test('caloriesProgress', () {
    final oats = sample(
      foods: [Food(name: 'Oats', kcal: 300, protein: 10, count: 1)],
    );
    expect(app.caloriesProgress(oats), closeTo(0.3, 0.001));
    final over = sample(
      foods: [Food(name: 'Pizza', kcal: 600, protein: 20, count: 2)],
    );
    expect(app.caloriesProgress(over), 1.0);
  });
}

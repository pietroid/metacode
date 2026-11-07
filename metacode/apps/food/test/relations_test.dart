import 'package:flutter_test/flutter_test.dart';

import '../generated/state.dart';
import 'fixtures.dart';

void main() {
  test('state.yaml loads and is usable', () {
    expect(app.caloriesText(app.initialState), '1,495 of 1,800 kcal');
  });

  test('food totals and tips', () {
    expect(app.foodTip(sample()), contains('breakfast'));
    final oats = sample(foods: [Food(name: 'Oats', kcal: 300, protein: 10, count: 1)]);
    expect(app.caloriesText(oats), '300 of 1,000 kcal');
    expect(app.caloriesProgress(oats), closeTo(0.3, 0.001));
    expect(app.foodTip(oats), contains('low on protein'));
    final over = sample(foods: [Food(name: 'Pizza', kcal: 600, protein: 20, count: 2)]);
    expect(app.foodTip(over), contains('200 kcal over'));
    expect(app.caloriesProgress(over), 1.0);
    expect(app.foodInfo(oats, 0), '300 kcal · 10 g protein');
  });
}

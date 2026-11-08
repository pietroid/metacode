// foodInfo: A short calorie/protein summary for a food item.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String foodInfo(State state, int index, Labels labels) =>
    '${state.foods[index].kcal.round()} ${labels.kcal} · ${state.foods[index].protein.round()} ${labels.gProtein}';

void main() {
  test('foodInfo', () {
    final oats = sample(
      foods: [Food(name: 'Oats', kcal: 300, protein: 10, count: 1)],
    );
    expect(app.foodInfo(oats, 0), '300 kcal · 10 g protein');
  });
}

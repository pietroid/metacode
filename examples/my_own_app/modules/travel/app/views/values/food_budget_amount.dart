// foodBudgetAmount: The selected day's food budget ("€40").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_day.dart';
import 'shared/euros.dart';

String foodBudgetAmount(State state, Labels labels) => euros(currentDay(state).food, labels);

void main() {
  test('foodBudgetAmount', () {
    expect(app.foodBudgetAmount(sample()), '€40');
    expect(app.foodBudgetAmount(sample(tripIndex: 1)), '€12.50');
    app.locale = 'pt_br';
    expect(app.foodBudgetAmount(sample(tripIndex: 1)), '€12,50');
    app.locale = null;
  });
}

// addFood10: Adds €10 to the selected day's food budget (a quick amount in the budget sheet).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/with_food_added.dart';

Future<void> addFood10(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(trips: withFoodAdded(state, 10)));

void main() {
  test('addFood10', () async {
    final s = await app.addFood10(sample(dayIndex: 1));
    expect(s.trips[0].days[1].food, 30 + 10);
  });
}

// addFood50: Adds €50 to the selected day's food budget (a quick amount in the budget sheet).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/with_food_added.dart';

Future<void> addFood50(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(trips: withFoodAdded(state, 50)));

void main() {
  test('addFood50', () async {
    final s = await app.addFood50(sample(dayIndex: 1));
    expect(s.trips[0].days[1].food, 30 + 50);
  });
}

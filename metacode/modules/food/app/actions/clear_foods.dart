// clearFoods: Resets every food count back to zero.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> clearFoods(State state, void Function(StateDelta) emit) async {
  for (final f in state.foods) {
    f.count = 0;
  }
  emit(StateDelta(foods: state.foods));
}

void main() {
  test('clearFoods resets every count to zero', () async {
    final base = await app.addFood(sample(), 0);
    final s = await app.clearFoods(base);
    expect(s.foods[0].count, 0);
    expect(s.foods[1].count, 0);
  });
}

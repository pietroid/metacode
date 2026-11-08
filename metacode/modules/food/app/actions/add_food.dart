// addFood: Adds one serving of the selected food to the daily log.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> addFood(
  State state,
  void Function(StateDelta) emit,
  int index,
) async {
  state.foods[index].count += 1;
  emit(StateDelta(foods: state.foods));
}

void main() {
  test('addFood increments the serving count', () async {
    final s = await app.addFood(sample(), 1);
    expect(s.foods[1].count, 1);
  });
}

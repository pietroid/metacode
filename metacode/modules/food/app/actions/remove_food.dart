// removeFood: Removes one serving of the tapped food from the log.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> removeFood(
  State state,
  void Function(StateDelta) emit,
  int index,
) async {
  if (state.foods[index].count <= 0) return;
  state.foods[index].count -= 1;
  emit(StateDelta(foods: state.foods));
}

void main() {
  test('removeFood decrements the serving count but not below zero', () async {
    final base = await app.addFood(sample(), 1);
    final s = await app.removeFood(base, 1);
    expect(s.foods[1].count, 0);
    expect((await app.removeFood(sample(), 0)).foods[0].count, 0);
  });
}

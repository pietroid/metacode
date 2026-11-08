// waterPlant: Waters the tapped plant and resets its next-due date.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> waterPlant(
  State state,
  void Function(StateDelta) emit,
  int index,
) async {
  state.plants[index].daysLeft = state.plants[index].everyDays;
  emit(StateDelta(plants: state.plants));
}

void main() {
  test('waterPlant resets the days left', () async {
    final s = await app.waterPlant(sample(), 0);
    expect(s.plants[0].daysLeft, 3);
  });
}

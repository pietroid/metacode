// nextDay: Advances every plant's schedule by one day.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> nextDay(State state, void Function(StateDelta) emit) async {
  for (final p in state.plants) {
    if (p.daysLeft > 0) p.daysLeft -= 1;
  }
  emit(StateDelta(plants: state.plants));
}

void main() {
  test('nextDay counts down every plant', () async {
    final s = await app.nextDay(sample());
    expect([s.plants[0].daysLeft, s.plants[1].daysLeft], [0, 1]);
  });
}

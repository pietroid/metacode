// previousDay: Moves to the trip's previous day (stays on the first).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> previousDay(State state, void Function(StateDelta) emit) async {
  final d = state.dayIndex.round();
  if (d > 0) emit(StateDelta(dayIndex: d - 1));
}

void main() {
  test('previousDay', () async {
    expect((await app.previousDay(sample(dayIndex: 1))).dayIndex, 0);
    expect((await app.previousDay(sample())).dayIndex, 0);
  });
}

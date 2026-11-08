// nextDay: Moves to the trip's next day (stays on the last).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/current_trip.dart';

Future<void> nextDay(State state, void Function(StateDelta) emit) async {
  final days = currentTrip(state).days;
  final d = state.dayIndex.round();
  if (d < days.length - 1) emit(StateDelta(dayIndex: d + 1));
}

void main() {
  test('nextDay', () async {
    expect((await app.nextDay(sample())).dayIndex, 1);
    expect((await app.nextDay(sample(dayIndex: 1))).dayIndex, 1);
  });
}

// isLastDay: Whether the last day is selected (no next day).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_trip.dart';

bool isLastDay(State state) {
  final days = currentTrip(state).days;
  return state.dayIndex.round() >= days.length - 1;
}

void main() {
  test('isLastDay', () {
    expect(app.isLastDay(sample(dayIndex: 1)), isTrue);
    expect(app.isLastDay(sample()), isFalse);
  });
}

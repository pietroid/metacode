// dayCellNumber: A day's date in the day grid (its day of the month).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_trip.dart';

String dayCellNumber(State state, int index) {
  final days = currentTrip(state).days;
  if (index >= days.length) return '';
  return '${days[index].dayOfMonth.round()}';
}

void main() {
  test('dayCellNumber', () {
    expect(app.dayCellNumber(sample(), 1), '16');
  });
}

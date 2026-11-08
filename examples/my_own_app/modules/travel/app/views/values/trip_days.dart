// tripDays: The open trip's days, for the day grid.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_trip.dart';

List<TripDay> tripDays(State state) => currentTrip(state).days;

void main() {
  test('tripDays', () {
    expect(app.tripDays(sample()).length, 2);
  });
}

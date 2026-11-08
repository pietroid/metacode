// openTripCost: The open trip's whole cost, the cost bar's last figure.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_trip.dart';
import 'shared/trip_total.dart';
import 'shared/euros.dart';

String openTripCost(State state, Labels labels) => euros(tripTotal(currentTrip(state)), labels);

void main() {
  test('openTripCost', () {
    expect(app.openTripCost(sample()), '€165');
  });
}

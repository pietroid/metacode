// openTripName: The open trip's name, for its header.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_trip.dart';
import 'shared/tr.dart';

String openTripName(State state, Labels labels) => tr(currentTrip(state).name, labels);

void main() {
  test('openTripName', () {
    expect(app.openTripName(sample(tripIndex: 1)), 'Kyoto');
  });
}

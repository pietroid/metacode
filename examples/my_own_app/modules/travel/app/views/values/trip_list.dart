// tripList: The trips, for the home list.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Trip> tripList(State state) => state.trips;

void main() {
  test('tripList', () {
    expect(app.tripList(sample()).length, 2);
  });
}

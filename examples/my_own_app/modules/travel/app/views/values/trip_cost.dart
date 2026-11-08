// tripCost: What a trip costs in all (plans and food), for its card.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/euros.dart';
import 'shared/trip_total.dart';

String tripCost(State state, Labels labels, int index) => euros(tripTotal(state.trips[index]), labels);

void main() {
  test('tripCost', () {
    expect(app.tripCost(sample(), 0), '€165');
  });
}

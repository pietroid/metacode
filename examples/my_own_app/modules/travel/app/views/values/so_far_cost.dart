// soFarCost: The trip's partial cost: every day up to and including the selected one.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_trip.dart';
import 'shared/day_total.dart';
import 'shared/euros.dart';

String soFarCost(State state, Labels labels) {
  final days = currentTrip(state).days;
  final last = state.dayIndex.round();
  num total = 0;
  for (var i = 0; i < days.length && i <= last; i++) {
    total += dayTotal(days[i]);
  }
  return euros(total, labels);
}

void main() {
  test('soFarCost', () {
    expect(app.soFarCost(sample()), '€65');
    expect(app.soFarCost(sample(dayIndex: 1)), '€165');
  });
}

// dayOfTotal: The selected day out of the trip ("Day 3 of 16").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_trip.dart';

String dayOfTotal(State state, Labels labels) {
  final days = currentTrip(state).days;
  return '${labels.day} ${state.dayIndex.round() + 1} ${labels.ofTotal} ${days.length}';
}

void main() {
  test('dayOfTotal', () {
    expect(app.dayOfTotal(sample()), 'Day 1 of 2');
    app.locale = 'pt_br';
    expect(app.dayOfTotal(sample()), 'Dia 1 de 2');
    app.locale = null;
  });
}

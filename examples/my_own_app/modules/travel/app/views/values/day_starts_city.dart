// dayStartsCity: Whether a day is the first in a new city (the day grid marks it).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_trip.dart';

bool dayStartsCity(State state, int index) {
  final days = currentTrip(state).days;
  if (index >= days.length) return false;
  if (index == 0) return true;
  return days[index].city.en != days[index - 1].city.en;
}

void main() {
  test('dayStartsCity', () {
    expect(app.dayStartsCity(sample(), 0), isTrue);
    expect(app.dayStartsCity(sample(), 1), isTrue);
  });
}

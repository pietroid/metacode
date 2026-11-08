// consultIsBooked: Whether the consultation is booked (the card shows a confirmation).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool consultIsBooked(State state) => state.consultBooked;

void main() {
  test('consultIsBooked', () {
    expect(app.consultIsBooked(sample(consultBooked: true)), true);
  });
}

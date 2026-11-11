// pickupOptions: The pickup times.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<PickupTime> pickupOptions(State state) {
  return [PickupTime.now, PickupTime.in15, PickupTime.in30];
}

void main() {
  test('3', () {
    expect(app.pickupOptions(sample()).length, 3);
  });
}

// pickupSelected: Whether pickup index is the chosen pickup time.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool pickupSelected(State state, int index) {
  if (index == 0) return state.pickup == PickupTime.now;
  if (index == 1) return state.pickup == PickupTime.in15;
  return state.pickup == PickupTime.in30;
}

void main() {
  test('initial', () {
    expect(app.pickupSelected(sample(), 0), true);
    expect(app.pickupSelected(sample(), 2), false);
  });
}

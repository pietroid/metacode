// selectPickup: sets pickup to the time at index.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> selectPickup(State state, void Function(StateDelta) emit, int index) async {
  const times = <PickupTime>[PickupTime.now, PickupTime.in15, PickupTime.in30];
  if (index < 0 || index >= times.length) return;
  emit(StateDelta(pickup: times[index]));
}

void main() {
  test('selectPickup', () async {
    final s = await app.selectPickup(sample(), 2);
    expect(s.pickup, PickupTime.in30);
  });
}

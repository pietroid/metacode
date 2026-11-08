// slotSelected: Whether consultation time [index] is the one picked.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool slotSelected(State state, int index) => state.consultSlot.round() == index;

void main() {
  test('slotSelected', () {
    expect(app.slotSelected(sample(consultSlot: 2), 2), true);
    expect(app.slotSelected(sample(consultSlot: 2), 0), false);
  });
}

// pickSlot: Picks consultation time [index] in the booking sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> pickSlot(State state, void Function(StateDelta) emit, int index) async {
  emit(StateDelta(consultSlot: index));
}

void main() {
  test('pickSlot', () async {
    expect((await app.pickSlot(sample(), 2)).consultSlot, 2);
  });
}

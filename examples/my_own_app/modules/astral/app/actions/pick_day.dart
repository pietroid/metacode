// pickDay: Keeps the birth day picked in the day dropdown; the map starts
// over (it is revealed again for the new date).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> pickDay(State state, void Function(StateDelta) emit, String value) async {
  emit(StateDelta(birthDay: value, readingStage: 0, dateInvalid: false));
}

void main() {
  test('pickDay keeps the day and hides the map', () async {
    final s = await app.pickDay(sample(readingStage: 5, dateInvalid: true), '30');
    expect(s.birthDay, '30');
    expect(s.readingStage, 0);
    expect(s.dateInvalid, false);
  });
}

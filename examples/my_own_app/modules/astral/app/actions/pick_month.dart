// pickMonth: Keeps the birth month picked in the month dropdown ('1' to
// '12'); the map starts over.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> pickMonth(State state, void Function(StateDelta) emit, String value) async {
  emit(StateDelta(birthMonth: value, readingStage: 0, dateInvalid: false));
}

void main() {
  test('pickMonth keeps the month and hides the map', () async {
    final s = await app.pickMonth(sample(readingStage: 5), '2');
    expect(s.birthMonth, '2');
    expect(s.readingStage, 0);
  });
}

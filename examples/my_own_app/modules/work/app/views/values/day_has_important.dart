// dayHasImportant: Whether a day has an important event.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool dayHasImportant(State state, int index) {
  for (final e in state.events) {
    if (e.day == index && e.important) return true;
  }
  return false;
}

void main() {
  test('dayHasImportant', () {
    expect(app.dayHasImportant(sample(), 0), isTrue);
    expect(app.dayHasImportant(sample(), 2), isFalse);
  });
}

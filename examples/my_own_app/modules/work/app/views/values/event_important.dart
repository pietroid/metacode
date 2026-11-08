// eventImportant: Whether an event is important.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/event_at.dart';
bool eventImportant(State state, int index) {
  final e = eventAt(state, state.selectedDay, index);
  if (e == null) return false;
  return e.important;
}

void main() {
  test('eventImportant', () {
    expect(app.eventImportant(sample(), 1), isTrue);
    expect(app.eventImportant(sample(selectedDay: 2), 1), isFalse);
  });
}

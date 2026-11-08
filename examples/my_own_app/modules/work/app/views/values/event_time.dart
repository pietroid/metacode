// eventTime: An event's start time.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/event_at.dart';
String eventTime(State state, int index) {
  final e = eventAt(state, state.selectedDay, index);
  if (e == null) return '';
  return e.time;
}

void main() {
  test('eventTime', () {
    expect(app.eventTime(sample(), 1), '11:00');
    expect(app.eventTime(sample(selectedDay: 2), 1), '');
  });
}

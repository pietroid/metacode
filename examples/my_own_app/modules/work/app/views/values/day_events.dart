// dayEvents: The selected day's events.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/events_on.dart';
List<Event> dayEvents(State state) => eventsOn(state, state.selectedDay);

void main() {
  test('dayEvents', () {
    expect(app.dayEvents(sample()).length, 2);
    expect(app.dayEvents(sample(selectedDay: 4)).length, 0);
  });
}

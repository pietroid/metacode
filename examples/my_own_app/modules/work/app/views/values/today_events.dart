// todayEvents: Today's (Monday's) events, for Today's schedule.
import 'package:flutter_test/flutter_test.dart';


import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/events_on.dart';

List<Event> todayEvents(State state) => eventsOn(state, 0);

void main() {
  test('todayEvents', () {
    expect(app.todayEvents(sample(selectedDay: 2)).length, 2);
  });
}

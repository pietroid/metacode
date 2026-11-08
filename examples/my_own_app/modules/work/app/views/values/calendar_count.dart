// calendarCount: How many events are on today (Monday), for Today.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String calendarCount(State state, Labels labels) {
  var n = 0;
  for (final e in state.events) {
    if (e.day == 0) n++;
  }
  return '$n ${labels.eventsToday}';
}

void main() {
  test('calendarCount', () {
    expect(app.calendarCount(sample()), '2 today');
  });
}

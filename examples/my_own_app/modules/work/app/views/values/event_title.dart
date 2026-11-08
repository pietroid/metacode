// eventTitle: An event's title.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/event_at.dart';
String eventTitle(State state, int index) {
  final e = eventAt(state, state.selectedDay, index);
  if (e == null) return '';
  return e.title;
}

void main() {
  test('eventTitle', () {
    expect(app.eventTitle(sample(selectedDay: 2), 0), 'Planning');
    expect(app.eventTitle(sample(selectedDay: 4), 0), '');
  });
}

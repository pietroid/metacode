// todayEventTime: One of today's events: start time.
import 'package:flutter_test/flutter_test.dart';


import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/event_at.dart';

String todayEventTime(State state, int index) {
  final e = eventAt(state, 0, index);
  if (e == null) return '';
  return e.time;
}

void main() {
  test('todayEventTime', () {
    expect(app.todayEventTime(sample(), 0), '9:30');
    expect(app.todayEventTime(sample(), 5), '');
  });
}

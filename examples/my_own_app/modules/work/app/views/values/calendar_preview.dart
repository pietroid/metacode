// calendarPreview: Today's first important event, time and title (else the first event), for Today.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String calendarPreview(State state, Labels labels) {
  for (final e in state.events) {
    if (e.day == 0 && e.important) return '${e.time} · ${e.title}';
  }
  for (final e in state.events) {
    if (e.day == 0) return '${e.time} · ${e.title}';
  }
  return labels.noEvents;
}

void main() {
  test('calendarPreview', () {
    expect(app.calendarPreview(sample()), '11:00 · Budget review');
    expect(app.calendarPreview(sample(events: [])), 'Nothing scheduled.');
  });
}

// openTripMeta: The open trip's dates and how long it is, under its name.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_trip.dart';
import 'shared/tr.dart';

String openTripMeta(State state, Labels labels) {
  final t = currentTrip(state);
  final days = t.days;
  return '${tr(t.dates, labels)} · ${days.length} ${labels.days}';
}

void main() {
  test('openTripMeta', () {
    expect(app.openTripMeta(sample()), 'Nov 15 – 16 · 2 days');
  });
}

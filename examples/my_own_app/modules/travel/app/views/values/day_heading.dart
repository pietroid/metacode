// dayHeading: The selected day and its city ("Day 2 · Sintra"), in the budget sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_day.dart';
import 'shared/tr.dart';

String dayHeading(State state, Labels labels) {
  final d = currentDay(state);
  return '${labels.day} ${state.dayIndex.round() + 1} · ${tr(d.city, labels)}';
}

void main() {
  test('dayHeading', () {
    expect(app.dayHeading(sample(dayIndex: 1)), 'Day 2 · Porto');
  });
}

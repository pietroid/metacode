// practiceText: A formatted summary of today's practice minutes.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String practiceText(State state, Labels labels) {
  final m = state.practiceMinutes.round();
  if (m >= 10) return '$m ${labels.minTodayGoalReached}';
  return '$m ${labels.ofTenMinToday}';
}

void main() {
  test('practiceText', () {
    expect(app.practiceText(sample(practiceMinutes: 5)), '5 of 10 min today');
  });
}

// allTimeText: How long Claude has worked on every example app together
// since each was loaded or reset, in minutes, on ProjectPage.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/all_history.dart';
import 'shared/format_minutes.dart';

String allTimeText(State state, Labels labels) {
  final h = allHistory(state);
  if (h == null) return '';
  return formatMinutes(h.ms, labels);
}

void main() {
  test('allTimeText sums minutes', () {
    final state = sample().copyWith(
        projectName: 'food', projectMs: 60000, projectTurns: 3,
        saved: [SavedDraft(name: 'work', project: sample().draft,
            cost: 0.25, ms: 30000, turns: 2)]);
    expect(app.allTimeText(state), '1.5 min');
  });
}

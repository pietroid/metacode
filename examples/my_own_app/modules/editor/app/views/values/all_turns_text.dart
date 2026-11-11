// allTurnsText: How many turns Claude has taken on every example app
// together since each was loaded or reset, on ProjectPage.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/all_history.dart';
import 'shared/format_turns.dart';

String allTurnsText(State state) {
  final h = allHistory(state);
  if (h == null) return '';
  return formatTurns(h.turns);
}

void main() {
  test('allTurnsText sums turns', () {
    final state = sample().copyWith(
        projectName: 'food', projectTurns: 3,
        saved: [SavedDraft(name: 'work', project: sample().draft,
            cost: 0.25, ms: 30000, turns: 2)]);
    expect(app.allTurnsText(state), '5');
  });
}

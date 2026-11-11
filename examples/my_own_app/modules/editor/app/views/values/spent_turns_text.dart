// spentTurnsText: How many turns Claude has taken on the example app at
// `index` (projectNames) since it was loaded or reset, on its ProjectTile.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../actions/shared/project_names.dart';
import '../../models/sample.dart';
import 'shared/format_turns.dart';
import 'shared/history_of.dart';

String spentTurnsText(State state, int index) {
  final names = projectNames();
  final h = historyOf(state, names[index]);
  if (h == null) return '';
  return formatTurns(h.turns);
}

void main() {
  test('spentTurnsText from saved', () {
    final state = sample().copyWith(saved: [SavedDraft(name: 'work',
        project: sample().draft, cost: 0.1, ms: 1000, turns: 2)]);
    expect(app.spentTurnsText(state, 2), '2');
  });
}

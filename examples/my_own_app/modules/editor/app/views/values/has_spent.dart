// hasSpent: Whether Claude has run on the example app at `index`
// (projectNames) since it was loaded or reset, so its ProjectTile shows the
// totals.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../actions/shared/project_names.dart';
import '../../models/sample.dart';
import 'shared/history_of.dart';

bool hasSpent(State state, int index) {
  final names = projectNames();
  return historyOf(state, names[index]) != null;
}

void main() {
  test('hasSpent for the current and the saved projects', () {
    final state = sample().copyWith(projectName: 'food', projectTurns: 3,
        saved: [SavedDraft(name: 'work', project: sample().draft,
            cost: 0.1, ms: 1000, turns: 2)]);
    expect(app.hasSpent(state, 0), isTrue);
    expect(app.hasSpent(state, 1), isFalse);
    expect(app.hasSpent(state, 2), isTrue);
  });
}

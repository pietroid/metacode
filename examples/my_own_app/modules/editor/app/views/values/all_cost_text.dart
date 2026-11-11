// allCostText: What Claude has cost every example app together since each
// was loaded or reset, in dollars, on ProjectPage.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/all_history.dart';
import 'shared/format_cost.dart';

String allCostText(State state) {
  final h = allHistory(state);
  if (h == null) return '';
  return formatCost(h.cost);
}

void main() {
  test('allCostText sums the current and saved projects', () {
    final state = sample().copyWith(
        projectName: 'food', projectCost: 0.5, projectTurns: 3,
        saved: [SavedDraft(name: 'work', project: sample().draft,
            cost: 0.25, ms: 1000, turns: 2)]);
    expect(app.allCostText(state), '\$0.75');
  });
}

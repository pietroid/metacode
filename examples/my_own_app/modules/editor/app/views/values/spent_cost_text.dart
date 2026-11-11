// spentCostText: What Claude has cost the example app at `index`
// (projectNames) since it was loaded or reset, in dollars, on its ProjectTile.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../actions/shared/project_names.dart';
import '../../models/sample.dart';
import 'shared/format_cost.dart';
import 'shared/history_of.dart';

String spentCostText(State state, int index) {
  final names = projectNames();
  final h = historyOf(state, names[index]);
  if (h == null) return '';
  return formatCost(h.cost);
}

void main() {
  test('spentCostText from saved', () {
    final state = sample().copyWith(saved: [SavedDraft(name: 'travel',
        project: sample().draft, cost: 1.2, ms: 640000, turns: 41)]);
    expect(app.spentCostText(state, 1), '\$1.20');
    expect(app.spentCostText(state, 0), '');
  });
}

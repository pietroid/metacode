// buildLine: One processing line: answers read, programs matched, budget fitted.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/money.dart';

String buildLine(State state, Labels labels, int index) {
  if (index == 0) return labels.buildRead;
  if (index == 1) return '${labels.buildMatches} ${state.matches.length}';
  return '${labels.buildBudget} ${money(state.budget, labels)}${labels.perMonth}';
}

void main() {
  test('buildLine', () async {
    final s = sample().copyWith(matches: [8, 10]);
    expect(app.buildLine(s, 1), 'Programs that fit you: 2');
    expect(app.buildLine(s, 2), r'Fitted to $300/mo');
  });
}

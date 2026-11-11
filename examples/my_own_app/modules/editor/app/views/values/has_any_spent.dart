// hasAnySpent: Whether Claude has run on any example app since it was
// loaded or reset, so ProjectPage shows the sum (allHistory).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/all_history.dart';

bool hasAnySpent(State state) => allHistory(state) != null;

void main() {
  test('hasAnySpent once a project has a run', () {
    expect(app.hasAnySpent(sample()), isFalse);
    expect(app.hasAnySpent(sample().copyWith(projectTurns: 2)), isTrue);
  });
}

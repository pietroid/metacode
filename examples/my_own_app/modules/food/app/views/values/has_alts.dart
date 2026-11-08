// hasAlts: Whether other programs match too (the picked one is always a match).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool hasAlts(State state) => state.matches.length > 1;

void main() {
  test('hasAlts', () async {
    expect(app.hasAlts(sample(goal: Goal.weightLoss, program: 8).copyWith(matches: [8])), false);
  });
}

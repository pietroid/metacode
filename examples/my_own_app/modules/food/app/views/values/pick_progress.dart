// pickProgress: How far the recipe picking is: picked of the days asked for (0 to 1).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

double pickProgress(State state) {
  if (state.days <= 0) return 0;
  final p = state.picked.length / state.days;
  if (p > 1) return 1;
  return p.toDouble();
}

void main() {
  test('pickProgress', () async {
    expect(app.pickProgress(sample(goal: Goal.weightLoss, program: 8).copyWith(picked: [12])), 0.2);
  });
}

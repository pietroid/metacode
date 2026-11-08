// hasPicked: Whether any recipe was accepted.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool hasPicked(State state) => state.picked.isNotEmpty;

void main() {
  test('hasPicked', () async {
    expect(app.hasPicked(sample(goal: Goal.weightLoss, program: 8).copyWith(picked: [12, 0])), true);
  });
}

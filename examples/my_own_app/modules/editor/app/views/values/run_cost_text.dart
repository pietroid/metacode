// runCostText: The last Claude run's cost, in dollars (next to a coins icon).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_cost.dart';

String runCostText(State state) => formatCost(state.runCost);

void main() {
  test('runCostText in dollars', () {
    expect(app.runCostText(sample().copyWith(runCost: 0.1234)), '\$0.12');
  });
}

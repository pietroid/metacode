// historyCostText: What Claude has cost the project in the editor since it
// was loaded or reset, in dollars.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_cost.dart';

String historyCostText(State state) => formatCost(state.projectCost);

void main() {
  test('historyCostText sums the project', () {
    expect(app.historyCostText(sample().copyWith(projectCost: 0.63)), '\$0.63');
  });
}

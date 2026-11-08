// budgetValue: The budget slider's position: the monthly budget in USD.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

double budgetValue(State state) => state.budget.toDouble();

void main() {
  test('budgetValue', () async {
    expect(app.budgetValue(sample(budget: 250)), 250.0);
  });
}

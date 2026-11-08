// budgetText: The monthly budget in the local currency, big on the budget step.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/money.dart';

String budgetText(State state, Labels labels) => money(state.budget, labels);

void main() {
  test('budgetText', () async {
    expect(app.budgetText(sample(budget: 1250)), r'$1,250');
    expect(app.budgetText(sample(budget: 40)), r'$40.00');
    app.locale = 'pt_br';
    expect(app.budgetText(sample(budget: 300)), r'R$ 1.500');
    app.locale = null;
  });
}

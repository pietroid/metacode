// budgetPerDay: Roughly what the monthly budget allows per day.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/money.dart';

String budgetPerDay(State state, Labels labels) => '≈ ${money(state.budget / 30, labels)} ${labels.aDay}';

void main() {
  test('budgetPerDay', () async {
    expect(app.budgetPerDay(sample(budget: 300)), r'≈ $10.00 a day');
  });
}

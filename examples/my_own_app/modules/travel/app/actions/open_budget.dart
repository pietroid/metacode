// openBudget: Opens the food budget sheet of the selected day, with an empty custom amount.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openBudget(
  State state,
  void Function(StateDelta) emit,
  Core core,
) async {
  emit(StateDelta(budgetDraft: ''));
  core.navigator.push(Routes.budget);
}

void main() {
  test('openBudget', () async {
    final s = await app.openBudget(sample(budgetDraft: '9'));
    expect(s.budgetDraft, '');
    expect(app.navigation, ['push budget']);
  });
}

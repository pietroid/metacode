// updateBudgetDraft: Keeps the custom amount typed in the budget sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> updateBudgetDraft(
  State state,
  void Function(StateDelta) emit,
  String value,
) async => emit(StateDelta(budgetDraft: value));

void main() {
  test('updateBudgetDraft', () async {
    expect((await app.updateBudgetDraft(sample(), '15')).budgetDraft, '15');
  });
}

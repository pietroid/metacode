// budgetDraftText: The custom amount typed in the budget sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String budgetDraftText(State state) => state.budgetDraft;

void main() {
  test('budgetDraftText', () {
    expect(app.budgetDraftText(sample(budgetDraft: '12')), '12');
  });
}

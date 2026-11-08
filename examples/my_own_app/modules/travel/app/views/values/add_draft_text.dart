// addDraftText: The budget sheet's add button: "Add €12" for a valid amount, else "Add amount".
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/parse_amount.dart';
import 'shared/euros.dart';

String addDraftText(State state, Labels labels) {
  final n = parseAmount(state.budgetDraft);
  if (n > 0) return '${labels.add} ${euros(n, labels)}';
  return labels.addAmount;
}

void main() {
  test('addDraftText', () {
    expect(app.addDraftText(sample(budgetDraft: '12')), 'Add €12');
    expect(app.addDraftText(sample(budgetDraft: 'abc')), 'Add amount');
  });
}

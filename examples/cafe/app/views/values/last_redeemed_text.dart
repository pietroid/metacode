// lastRedeemedText: the last redeemed reward with the redeemed label.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String lastRedeemedText(State state, Labels labels) =>
    '${state.lastRedeemed} - ${labels.redeemed}';

void main() {
  test('lastRedeemedText', () {
    final t = app.lastRedeemedText(sample({'lastRedeemed': 'Free drink'}));
    expect(t.startsWith('Free drink'), true);
    expect(t.contains('Show this at pickup'), true);
  });
}

// runTurnsText: How many turns the last Claude run took (next to a chat
// icon).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_turns.dart';

String runTurnsText(State state) =>
    formatTurns(state.runTurns);

void main() {
  test('runTurnsText counts turns', () {
    expect(app.runTurnsText(sample().copyWith(runTurns: 7)), '7');
  });
}

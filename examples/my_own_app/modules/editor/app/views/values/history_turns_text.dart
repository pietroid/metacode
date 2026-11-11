// historyTurnsText: How many turns Claude has taken on the project in the
// editor since it was loaded or reset.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_turns.dart';

String historyTurnsText(State state) =>
    formatTurns(state.projectTurns);

void main() {
  test('historyTurnsText counts turns', () {
    expect(app.historyTurnsText(sample().copyWith(projectTurns: 25)), '25');
  });
}

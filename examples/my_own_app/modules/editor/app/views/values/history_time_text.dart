// historyTimeText: How long Claude has worked on the project in the editor
// since it was loaded or reset, in minutes.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_minutes.dart';

String historyTimeText(State state, Labels labels) =>
    formatMinutes(state.projectMs, labels);

void main() {
  test('historyTimeText in minutes', () {
    expect(app.historyTimeText(sample().copyWith(projectMs: 310000)), '5.2 min');
  });
}

// nextUpMeta: Why NextUpCard's item is first: how overdue the follow-up is, Urgent, or focus time.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';


String nextUpMeta(State state, Labels labels) {
  for (final f in state.followUps) {
    if (!f.done && f.dueIn < 0) return '${0 - f.dueIn.round()}${labels.daysShort} ${labels.overdue}';
  }
  for (final t in state.tasks) {
    if (!t.done && t.urgent) return labels.urgent;
  }
  return labels.focusTime;
}

void main() {
  test('nextUpMeta', () {
    expect(app.nextUpMeta(sample()), '2d overdue');
    expect(app.nextUpMeta(sample(followUps: [])), 'Urgent');
    expect(app.nextUpMeta(sample(followUps: [], tasks: [])), 'Focus time');
  });
}

// nextUpText: The single most pressing item: an overdue follow-up, else an urgent to-do, else an all-clear.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String nextUpText(State state, Labels labels) {
  for (final f in state.followUps) {
    if (!f.done && f.dueIn < 0) return '${labels.chaseUp} ${f.person}: ${f.topic}';
  }
  for (final t in state.tasks) {
    if (!t.done && t.urgent) return '${labels.finish}: ${t.title}';
  }
  return labels.allClear;
}

void main() {
  test('nextUpText', () {
    expect(app.nextUpText(sample()), 'Chase Tom: SOW');
    expect(app.nextUpText(sample(followUps: [])), 'Finish: Review budget');
    expect(app.nextUpText(sample(followUps: [], tasks: [])), startsWith('Nothing urgent'));
  });
}

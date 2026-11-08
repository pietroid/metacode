// followUpPreview: The most overdue open follow-up, person and topic, for Today.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String followUpPreview(State state, Labels labels) {
  FollowUp? first;
  for (final f in state.followUps) {
    if (!f.done && (first == null || f.dueIn < first.dueIn)) first = f;
  }
  if (first == null) return labels.nothingPending;
  return '${first.person} · ${first.topic}';
}

void main() {
  test('followUpPreview', () {
    expect(app.followUpPreview(sample()), 'Tom · SOW');
    expect(app.followUpPreview(sample(followUps: [])), 'Nothing pending.');
  });
}

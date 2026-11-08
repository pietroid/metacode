// followUpCount: How many follow-ups are open, for the Follow-ups header.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String followUpCount(State state, Labels labels) {
  var n = 0;
  for (final f in state.followUps) {
    if (!f.done) n++;
  }
  return '$n ${labels.open}';
}

void main() {
  test('followUpCount', () {
    expect(app.followUpCount(sample()), '2 open');
  });
}

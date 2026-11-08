// followUpOverdue: Whether an open follow-up is past its due date.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool followUpOverdue(State state, int index) {
  final f = state.followUps[index];
  return !f.done && f.dueIn < 0;
}

void main() {
  test('followUpOverdue', () {
    expect(app.followUpOverdue(sample(), 0), isTrue);
    expect(app.followUpOverdue(sample(), 1), isFalse);
  });
}

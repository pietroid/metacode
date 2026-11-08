// followUpDone: Whether a follow-up is closed.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool followUpDone(State state, int index) => state.followUps[index].done;

void main() {
  test('followUpDone', () {
    expect(app.followUpDone(sample(), 2), isTrue);
  });
}

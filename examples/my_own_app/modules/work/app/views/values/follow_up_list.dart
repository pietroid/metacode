// followUpList: The follow-ups.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<FollowUp> followUpList(State state) => state.followUps;

void main() {
  test('followUpList', () {
    expect(app.followUpList(sample()).length, 3);
  });
}

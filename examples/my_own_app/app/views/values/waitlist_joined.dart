// waitlistJoined: Whether the user has already joined the waitlist.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool waitlistJoined(State state) =>
    state.waitlistStatus == WaitlistStatus.joined;

void main() {
  test('waitlistJoined', () {
    expect(
      app.waitlistJoined(sample(waitlistStatus: WaitlistStatus.joined)),
      isTrue,
    );
  });
}

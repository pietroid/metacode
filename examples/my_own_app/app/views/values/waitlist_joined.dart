// waitlistJoined: Whether the user has joined the waitlist (their remote
// waitlistEmail is set, on every tab of this browser).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool waitlistJoined(State state) => state.waitlistEmail.isNotEmpty;

void main() {
  test('waitlistJoined', () {
    expect(app.waitlistJoined(sample(waitlistEmail: 'ada@example.com')), isTrue);
    expect(app.waitlistJoined(sample()), isFalse);
  });
}

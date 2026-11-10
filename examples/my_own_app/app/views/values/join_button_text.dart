// joinButtonText: The join button's text: "Join waitlist", or "Joining…"
// while it's sent.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String joinButtonText(State state, Labels labels) =>
    state.waitlistStatus == WaitlistStatus.sending
        ? labels.joiningText
        : labels.joinWaitlistText;

void main() {
  test('joinButtonText', () {
    expect(app.joinButtonText(sample()), 'Join waitlist');
    expect(app.joinButtonText(sample(waitlistStatus: WaitlistStatus.sending)),
        'Joining…');
  });
}

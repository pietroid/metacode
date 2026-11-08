// joinWaitlist: Validates the email and marks the user as joined on the waitlist.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

bool _joinWaitlistLooksLikeEmail(String text) {
  final t = text.trim();
  final at = t.indexOf('@');
  return at > 0 &&
      t.lastIndexOf('.') > at + 1 &&
      !t.endsWith('.') &&
      !t.contains(' ');
}

Future<void> joinWaitlist(State state, void Function(StateDelta) emit) async {
  if (state.waitlistStatus == WaitlistStatus.joined) return;
  if (!_joinWaitlistLooksLikeEmail(state.email)) {
    return emit(StateDelta(waitlistStatus: WaitlistStatus.invalid));
  }
  emit(
    StateDelta(
      email: state.email.trim(),
      waitlistStatus: WaitlistStatus.joined,
      waitlistCount: state.waitlistCount + 1,
    ),
  );
}

void main() {
  test('joinWaitlist validates the email', () async {
    for (final bad in [
      '',
      'ada',
      'ada@',
      'ada@site',
      '@site.com',
      'ada@site.',
    ]) {
      final s = await app.joinWaitlist(sample(email: bad));
      expect(s.waitlistStatus, WaitlistStatus.invalid, reason: bad);
      expect(s.waitlistCount, 1284);
    }
  });

  test('joinWaitlist joins once', () async {
    final s = await app.joinWaitlist(sample(email: ' ada@example.com '));
    expect(s.waitlistStatus, WaitlistStatus.joined);
    expect(s.email, 'ada@example.com');
    expect(s.waitlistCount, 1285);
    expect((await app.joinWaitlist(s)).waitlistCount, 1285);
  });
}

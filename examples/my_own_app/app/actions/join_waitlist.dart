// joinWaitlist: Validates the email, shows the button as sending and calls
// the remote joinWaitlist, which adds it on the backend. When it's done the
// dialog shows "You're on the list" (waitlistEmail is set) and the count
// is the backend's; offline or refused, "try again".
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/looks_like_email.dart';

Future<void> joinWaitlist(
  State state,
  void Function(StateDelta) emit,
  Remote remote,
) async {
  if (state.waitlistStatus == WaitlistStatus.sending ||
      state.waitlistEmail.isNotEmpty) {
    return;
  }
  final email = state.email.trim();
  if (!looksLikeEmail(email)) {
    return emit(StateDelta(waitlistStatus: WaitlistStatus.invalid));
  }
  emit(StateDelta(waitlistStatus: WaitlistStatus.sending));
  final error = await remote.joinWaitlist(email);
  emit(StateDelta(
    waitlistStatus: error == null ? WaitlistStatus.idle : WaitlistStatus.failed,
  ));
}

void main() {
  test('joinWaitlist validates the email before calling the backend', () async {
    final s = await app.joinWaitlist(sample(email: 'ada@site'));
    expect(s.waitlistStatus, WaitlistStatus.invalid);
    expect(app.remoteCalls, isEmpty);
    expect(s.waitlistCount, 1284);
  });

  test('joinWaitlist joins once; the backend counts each email once', () async {
    app.system = {'waitlist': <String>[]};
    final s = await app.joinWaitlist(sample(email: ' Ada@Example.com '));
    expect(app.remoteCalls, ['joinWaitlist']);
    expect(app.emitted.first, {'waitlistStatus': 'sending'});
    expect(s.waitlistStatus, WaitlistStatus.idle);
    expect(s.waitlistEmail, 'ada@example.com');
    expect(s.waitlistCount, 1285);
    expect(app.system['waitlist'], ['ada@example.com']);
    // Joined: nothing more to send.
    expect((await app.joinWaitlist(s)).waitlistCount, 1285);
    expect(app.remoteCalls, isEmpty);
    // The same email from another device isn't counted twice.
    final again = await app.joinWaitlist(sample(email: 'ada@example.com', waitlistCount: 1285));
    expect(again.waitlistCount, 1285);
    expect(again.waitlistEmail, 'ada@example.com');
  });

  test('joinWaitlist offline: failed, nothing joined', () async {
    app.offline = true;
    addTearDown(() => app.offline = false);
    final s = await app.joinWaitlist(sample(email: 'ada@example.com'));
    expect(s.waitlistStatus, WaitlistStatus.failed);
    expect(s.waitlistEmail, '');
    expect(s.waitlistCount, 1284);
  });
}

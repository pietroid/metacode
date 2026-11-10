// updateEmail: Updates the waitlist email as the user types; clears an
// invalid or failed status.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> updateEmail(
  State state,
  void Function(StateDelta) emit,
  String value,
) async {
  if (state.waitlistStatus == WaitlistStatus.invalid ||
      state.waitlistStatus == WaitlistStatus.failed) {
    return emit(StateDelta(email: value, waitlistStatus: WaitlistStatus.idle));
  }
  emit(StateDelta(email: value));
}

void main() {
  test('updateEmail clears an invalid or failed status', () async {
    for (final status in [WaitlistStatus.invalid, WaitlistStatus.failed]) {
      final s = await app.updateEmail(sample(waitlistStatus: status), 'a@b.co');
      expect(s.email, 'a@b.co');
      expect(s.waitlistStatus, WaitlistStatus.idle);
    }
  });
}

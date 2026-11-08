// updateEmail: Updates the waitlist email as the user types.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> updateEmail(
  State state,
  void Function(StateDelta) emit,
  String value,
) async {
  if (state.waitlistStatus == WaitlistStatus.invalid) {
    return emit(StateDelta(email: value, waitlistStatus: WaitlistStatus.idle));
  }
  emit(StateDelta(email: value));
}

void main() {
  test('updateEmail clears an invalid status', () async {
    final s = await app.updateEmail(
      sample(waitlistStatus: WaitlistStatus.invalid),
      'a@b.co',
    );
    expect(s.email, 'a@b.co');
    expect(s.waitlistStatus, WaitlistStatus.idle);
  });
}

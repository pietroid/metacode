// waitlistSending: Whether the email is being sent to the backend (the
// join button shows it).
import '../../../.generated/state.dart';

bool waitlistSending(State state) =>
    state.waitlistStatus == WaitlistStatus.sending;

// waitlistFailed: Whether the last join couldn't reach the backend (or it
// refused): the form says to try again.
import '../../../.generated/state.dart';

bool waitlistFailed(State state) =>
    state.waitlistStatus == WaitlistStatus.failed;

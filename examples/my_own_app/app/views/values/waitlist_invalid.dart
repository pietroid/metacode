// waitlistInvalid: Whether the current email fails validation.
import '../../../.generated/state.dart';

bool waitlistInvalid(State state) =>
    state.waitlistStatus == WaitlistStatus.invalid;

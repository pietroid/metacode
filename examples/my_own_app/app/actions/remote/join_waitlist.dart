// joinWaitlist: The remote action (runs on the backend): validates the
// email again (the value is untrusted), adds it to the waitlist (system,
// never sent), counts it once (shared: everyone's footer updates) and marks
// the caller as joined (remote).
import '../../../.generated/remote_state.dart';
import '../shared/looks_like_email.dart';

Future<void> joinWaitlist(
  State state,
  void Function(StateDelta) emit,
  String value,
) async {
  final email = value.trim().toLowerCase();
  if (!looksLikeEmail(email)) throw RemoteError('invalidEmail');
  if (state.waitlist.contains(email)) {
    return emit(StateDelta(waitlistEmail: email));
  }
  emit(StateDelta(
    waitlist: [...state.waitlist, email],
    waitlistCount: state.waitlistCount + 1,
    waitlistEmail: email,
  ));
}

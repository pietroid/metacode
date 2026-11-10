// joinedText: The confirmation message shown after joining the waitlist.
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';

String joinedText(State state, Labels labels) =>
    '${labels.weWillEmail} ${state.waitlistEmail} ${labels.whenYourSpotOpens}';

// exampleReply: The assistant's reply for the currently visible example: the app it made and what it has.
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';

String exampleReply(State state, Labels labels) {
  final i = state.exampleIndex.round();
  if (i == 1) return labels.replyWork;
  if (i == 2) return labels.replyTravel;
  if (i == 3) return labels.replyAstral;
  return labels.replyFood;
}

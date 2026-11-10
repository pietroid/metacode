// votesText: The shared vote count and the caller's nickname.
import '../../../.generated/state.dart';

String votesText(State state) =>
    'Votes: ${state.votes} ${state.nickname}${state.voteError}';

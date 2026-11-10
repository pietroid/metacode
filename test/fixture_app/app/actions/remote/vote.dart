// vote: The remote action: counts one vote per nickname (system `voters`,
// shared `votes`) and saves the caller's nickname (remote). Refuses an
// empty one.
import '../../../.generated/remote_state.dart';
import '../shared/clean_name.dart';

Future<void> vote(State state, void Function(StateDelta) emit, String value) async {
  final name = cleanName(value);
  if (name.isEmpty) throw RemoteError('emptyName');
  if (state.voters.contains(name)) return emit(StateDelta(nickname: name));
  emit(StateDelta(
    voters: [...state.voters, name],
    votes: state.votes + 1,
    nickname: name,
  ));
}

// fetchNickname: The remote action with HTTP (`api`): sets the caller's
// nickname to the body of a GET, refusing a failed request.
import '../../../.generated/api.dart';
import '../../../.generated/remote_state.dart';

Future<void> fetchNickname(
    State state, void Function(StateDelta) emit, Api api) async {
  final r = await api.get('https://example.com/nickname');
  if (!r.ok) throw RemoteError('fetchFailed');
  emit(StateDelta(nickname: r.body));
}

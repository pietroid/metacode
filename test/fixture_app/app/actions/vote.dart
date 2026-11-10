// vote: Votes as `Ada` through the remote `vote`; a refusal or no
// connection shows in voteError.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/clean_name.dart';

Future<void> vote(State state, void Function(StateDelta) emit, Remote remote) async {
  emit(StateDelta(voteError: ''));
  final error = await remote.vote(cleanName('Ada'));
  if (error != null) emit(StateDelta(voteError: error.code));
}

void main() {
  test('votes once per nickname; the remote action runs in-process', () async {
    var state = await app.vote(sample());
    expect(app.remoteCalls, ['vote']);
    expect(state.votes, 1);
    expect(state.nickname, 'ada');
    expect(app.system['voters'], ['ada']);
    state = await app.vote(state);
    expect(state.votes, 1);
  });

  test('offline: the error code', () async {
    app.offline = true;
    addTearDown(() => app.offline = false);
    final state = await app.vote(sample());
    expect(state.voteError, 'offline');
    expect(state.votes, 0);
  });
}

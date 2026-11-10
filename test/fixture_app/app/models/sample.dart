// sample: test fixtures.
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

final app = TestApp();

State sample({
  int count = 0,
  bool started = false,
  String voteError = '',
  String nickname = '',
  num votes = 0,
}) =>
    State(
      voteError: voteError,
      count: count,
      started: started,
      nickname: nickname,
      votes: votes,
    );

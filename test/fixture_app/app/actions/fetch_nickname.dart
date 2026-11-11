// fetchNickname: Asks the backend's fetchNickname (which makes the HTTP
// request: local actions have no network) for a nickname.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/api.dart';
import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> fetchNickname(State state, Remote remote) async {
  await remote.fetchNickname();
}

void main() {
  test('fetchNickname: the remote action makes the request', () async {
    app.api = (method, url, body) => ApiResponse(status: 200, body: 'Ada');
    final state = await app.fetchNickname(sample());
    expect(app.requests, ['GET https://example.com/nickname']);
    expect(state.nickname, 'Ada');
  });

  test('fetchNickname: a failed request refuses', () async {
    app.api = (method, url, body) => ApiResponse(status: 500, body: '');
    final state = await app.fetchNickname(sample());
    expect(state.nickname, '');
  });
}

// openFollowUps: Opens the follow-ups.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openFollowUps(State state, Core core) async {
  core.navigator.push(Routes.followUps);
}

void main() {
  test('openFollowUps', () async {
    await app.openFollowUps(sample());
    expect(app.navigation, ['push followUps']);
  });
}

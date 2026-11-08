// openInbox: Opens the inbox.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openInbox(State state, Core core) async {
  core.navigator.push(Routes.inbox);
}

void main() {
  test('openInbox', () async {
    await app.openInbox(sample());
    expect(app.navigation, ['push inbox']);
  });
}

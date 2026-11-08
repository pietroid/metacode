// inboxCount: How many messages are unread, for the Inbox header.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String inboxCount(State state, Labels labels) {
  var n = 0;
  for (final m in state.messages) {
    if (m.unread) n++;
  }
  return '$n ${labels.unread}';
}

void main() {
  test('inboxCount', () {
    expect(app.inboxCount(sample()), '1 unread');
  });
}

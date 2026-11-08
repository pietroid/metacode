// messageUnread: Whether a message is unread.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool messageUnread(State state, int index) => state.messages[index].unread;

void main() {
  test('messageUnread', () {
    expect(app.messageUnread(sample(), 0), isTrue);
  });
}

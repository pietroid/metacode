// messageList: The inbox messages.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Message> messageList(State state) => state.messages;

void main() {
  test('messageList', () {
    expect(app.messageList(sample()).length, 2);
  });
}

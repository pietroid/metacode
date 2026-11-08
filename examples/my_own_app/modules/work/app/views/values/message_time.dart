// messageTime: When a message arrived.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String messageTime(State state, int index) => state.messages[index].time;

void main() {
  test('messageTime', () {
    expect(app.messageTime(sample(), 0), '8:42');
  });
}

// messageSender: Who sent a message.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String messageSender(State state, int index) => state.messages[index].sender;

void main() {
  test('messageSender', () {
    expect(app.messageSender(sample(), 1), 'Legal');
  });
}

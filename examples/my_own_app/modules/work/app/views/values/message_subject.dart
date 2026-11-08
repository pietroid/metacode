// messageSubject: A message's subject line.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String messageSubject(State state, int index) => state.messages[index].subject;

void main() {
  test('messageSubject', () {
    expect(app.messageSubject(sample(), 0), 'Budget');
  });
}

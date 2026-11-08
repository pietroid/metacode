// markRead: Marks an inbox message as read.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> markRead(
  State state,
  void Function(StateDelta) emit,
  int index,
) async {
  state.messages[index].unread = false;
  emit(StateDelta(messages: state.messages));
}

void main() {
  test('markRead clears unread', () async {
    final s = await app.markRead(sample(), 0);
    expect(s.messages[0].unread, isFalse);
  });
}

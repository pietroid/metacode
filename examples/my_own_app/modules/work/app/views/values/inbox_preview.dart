// inboxPreview: The newest unread message, sender and subject, for Today; inbox zero when none.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String inboxPreview(State state, Labels labels) {
  for (final m in state.messages) {
    if (m.unread) return '${m.sender} · ${m.subject}';
  }
  return labels.inboxZero;
}

void main() {
  test('inboxPreview', () {
    expect(app.inboxPreview(sample()), 'Marta Silva · Budget');
    expect(app.inboxPreview(sample(messages: [])), 'Inbox zero.');
  });
}

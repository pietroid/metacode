// messageInitials: The sender's initials (up to two) for the avatar.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String messageInitials(State state, int index) {
  final parts = state.messages[index].sender.split(' ');
  var out = "";
  for (final p in parts) {
    if (p.isNotEmpty && out.length < 2) out += p[0];
  }
  return out.toUpperCase();
}

void main() {
  test('messageInitials', () {
    expect(app.messageInitials(sample(), 0), 'MS');
    expect(app.messageInitials(sample(), 1), 'L');
  });
}

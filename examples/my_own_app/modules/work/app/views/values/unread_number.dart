// unreadNumber: How many messages are unread, as a number, for its StatTile.
import 'package:flutter_test/flutter_test.dart';


import '../../../.generated/state.dart';
import '../../models/sample.dart';


String unreadNumber(State state) {
  var n = 0;
  for (final m in state.messages) {
    if (m.unread) n++;
  }
  return '$n';
}

void main() {
  test('unreadNumber', () {
    expect(app.unreadNumber(sample()), '1');
  });
}

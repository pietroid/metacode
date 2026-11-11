// setNotifications: sets notificationsOn to the value.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setNotifications(State state, void Function(StateDelta) emit, bool value) async {
  emit(StateDelta(notificationsOn: value));
}

void main() {
  test('setNotifications', () async {
    final s = await app.setNotifications(sample(), false);
    expect(s.notificationsOn, false);
  });
}

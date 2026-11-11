// notificationsEnabled: whether order notifications are on.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool notificationsEnabled(State state) => state.notificationsOn;

void main() {
  test('notificationsEnabled', () {
    expect(app.notificationsEnabled(sample()), true);
  });
  test('notificationsEnabled off', () {
    expect(app.notificationsEnabled(sample({'notificationsOn': false})), false);
  });
}

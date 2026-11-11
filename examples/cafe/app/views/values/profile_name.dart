// profileName: the user name, or Guest when blank.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String profileName(State state) {
  if (state.userName.trim().isEmpty) return 'Guest';
  return state.userName;
}

void main() {
  test('profileName', () {
    expect(app.profileName(sample()), 'Alex Rivera');
  });
  test('profileName blank', () {
    expect(app.profileName(sample({'userName': '  '})), 'Guest');
  });
}

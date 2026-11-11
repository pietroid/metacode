// themeIcon: icon of theme choice index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String themeIcon(State state, int index) {
  if (index == 0) return 'settings';
  if (index == 1) return 'lightMode';
  return 'darkMode';
}

void main() {
  test('themeIcon', () {
    expect(app.themeIcon(sample(), 1), 'lightMode');
    expect(app.themeIcon(sample(), 2), 'darkMode');
  });
}

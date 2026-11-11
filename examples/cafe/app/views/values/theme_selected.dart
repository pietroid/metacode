// themeSelected: whether theme choice index is the selected one.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool themeSelected(State state, int index) {
  if (index == 0) return state.themeChoice == ThemeChoice.system;
  if (index == 1) return state.themeChoice == ThemeChoice.light;
  return state.themeChoice == ThemeChoice.dark;
}

void main() {
  test('themeSelected', () {
    expect(app.themeSelected(sample(), 0), true);
    expect(app.themeSelected(sample(), 1), false);
  });
}

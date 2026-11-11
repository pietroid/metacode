// themeOptions: the theme choices.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<ThemeChoice> themeOptions(State state) =>
    [ThemeChoice.system, ThemeChoice.light, ThemeChoice.dark];

void main() {
  test('themeOptions', () {
    expect(app.themeOptions(sample()).length, 3);
  });
}

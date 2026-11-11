// selectTheme: sets themeChoice to the choice at index.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> selectTheme(State state, void Function(StateDelta) emit, int index) async {
  const themes = <ThemeChoice>[ThemeChoice.system, ThemeChoice.light, ThemeChoice.dark];
  if (index < 0 || index >= themes.length) return;
  emit(StateDelta(themeChoice: themes[index]));
}

void main() {
  test('selectTheme', () async {
    final s = await app.selectTheme(sample(), 2);
    expect(s.themeChoice, ThemeChoice.dark);
  });
}

// useDark: Shows every app in the dark theme (core.theme.set).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> useDark(State state, Core core) async {
  await core.theme.set('dark');
}

void main() {
  test('useDark asks for the dark theme', () async {
    await app.useDark(sample());
    expect(app.theme, 'dark');
  });
}

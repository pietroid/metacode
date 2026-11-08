// toggleStreak: Adds or removes the weekly streak card in the studio preview app, after a short "updating" moment.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long the preview shows "Updating your app" before the change lands.
const int _toggleStreakMs = 900;

Future<void> toggleStreak(State state, void Function(StateDelta) emit, bool value) async {
  if (state.buildStep != 5 || state.tweaking) return;
  emit(StateDelta(tweaking: true, appStreak: value));
  await Future.delayed(Duration(milliseconds: _toggleStreakMs));
  emit(StateDelta(tweaking: false));
}

void main() {
  test('toggleStreak updates the preview app', () async {
    final s = await app.toggleStreak(sample(buildStep: 5), true);
    expect(s.tweaking, isFalse);
    expect(s.appStreak, isTrue);
  });

  test('toggleStreak waits until the app is made', () async {
    await app.toggleStreak(sample(buildStep: 0), true);
    expect(app.emitted, isEmpty);
  });
}

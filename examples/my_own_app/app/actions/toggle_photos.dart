// togglePhotos: Adds or removes photos in the studio preview app, after a short "updating" moment.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long the preview shows "Updating your app" before the change lands.
const int _togglePhotosMs = 900;

Future<void> togglePhotos(State state, void Function(StateDelta) emit, bool value) async {
  if (state.buildStep != 5 || state.tweaking) return;
  emit(StateDelta(tweaking: true, appPhotos: value));
  await Future.delayed(Duration(milliseconds: _togglePhotosMs));
  emit(StateDelta(tweaking: false));
}

void main() {
  test('togglePhotos updates the preview app', () async {
    final s = await app.togglePhotos(sample(buildStep: 5), true);
    expect(s.tweaking, isFalse);
    expect(s.appPhotos, isTrue);
  });

  test('togglePhotos waits until the app is made', () async {
    await app.togglePhotos(sample(buildStep: 0), true);
    expect(app.emitted, isEmpty);
  });
}

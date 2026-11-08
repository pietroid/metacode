// colorPurple: Repaints the studio preview app purple, after a short "updating" moment.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long the preview shows "Updating your app" before the change lands.
const int _colorPurpleMs = 900;

Future<void> colorPurple(State state, void Function(StateDelta) emit) async {
  if (state.buildStep != 5 || state.tweaking) return;
  emit(StateDelta(tweaking: true, appColor: AppColor.purple));
  await Future.delayed(Duration(milliseconds: _colorPurpleMs));
  emit(StateDelta(tweaking: false));
}

void main() {
  test('colorPurple updates the preview app', () async {
    final s = await app.colorPurple(sample(buildStep: 5, appColor: AppColor.orange));
    expect(s.tweaking, isFalse);
    expect(s.appColor, AppColor.purple);
  });

  test('colorPurple waits until the app is made', () async {
    await app.colorPurple(sample(buildStep: 0, appColor: AppColor.orange));
    expect(app.emitted, isEmpty);
  });
}

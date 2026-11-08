// colorBlue: Repaints the studio preview app blue, after a short "updating" moment.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long the preview shows "Updating your app" before the change lands.
const int _colorBlueMs = 900;

Future<void> colorBlue(State state, void Function(StateDelta) emit) async {
  if (state.buildStep != 5 || state.tweaking) return;
  emit(StateDelta(tweaking: true, appColor: AppColor.blue));
  await Future.delayed(Duration(milliseconds: _colorBlueMs));
  emit(StateDelta(tweaking: false));
}

void main() {
  test('colorBlue updates the preview app', () async {
    final s = await app.colorBlue(sample(buildStep: 5, appColor: AppColor.purple));
    expect(s.tweaking, isFalse);
    expect(s.appColor, AppColor.blue);
  });

  test('colorBlue waits until the app is made', () async {
    await app.colorBlue(sample(buildStep: 0, appColor: AppColor.purple));
    expect(app.emitted, isEmpty);
  });
}

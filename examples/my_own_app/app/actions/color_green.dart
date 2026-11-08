// colorGreen: Repaints the studio preview app green, after a short "updating" moment.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long the preview shows "Updating your app" before the change lands.
const int _colorGreenMs = 900;

Future<void> colorGreen(State state, void Function(StateDelta) emit) async {
  if (state.buildStep != 5 || state.tweaking) return;
  emit(StateDelta(tweaking: true, appColor: AppColor.green));
  await Future.delayed(Duration(milliseconds: _colorGreenMs));
  emit(StateDelta(tweaking: false));
}

void main() {
  test('colorGreen updates the preview app', () async {
    final s = await app.colorGreen(sample(buildStep: 5, appColor: AppColor.purple));
    expect(s.tweaking, isFalse);
    expect(s.appColor, AppColor.green);
  });

  test('colorGreen waits until the app is made', () async {
    await app.colorGreen(sample(buildStep: 0, appColor: AppColor.purple));
    expect(app.emitted, isEmpty);
  });
}

// colorOrange: Repaints the studio preview app orange, after a short "updating" moment.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long the preview shows "Updating your app" before the change lands.
const int _colorOrangeMs = 900;

Future<void> colorOrange(State state, void Function(StateDelta) emit) async {
  if (state.buildStep != 5 || state.tweaking) return;
  emit(StateDelta(tweaking: true, appColor: AppColor.orange));
  await Future.delayed(Duration(milliseconds: _colorOrangeMs));
  emit(StateDelta(tweaking: false));
}

void main() {
  test('colorOrange updates the preview app', () async {
    final s = await app.colorOrange(sample(buildStep: 5, appColor: AppColor.purple));
    expect(s.tweaking, isFalse);
    expect(s.appColor, AppColor.orange);
  });

  test('colorOrange waits until the app is made', () async {
    await app.colorOrange(sample(buildStep: 0, appColor: AppColor.purple));
    expect(app.emitted, isEmpty);
  });
}

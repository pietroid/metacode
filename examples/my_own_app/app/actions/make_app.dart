// makeApp: Runs the studio demo: walks the four build steps, then shows the
// preview app with its tweaks reset. An empty idea becomes the plants one.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/labels.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long each build step shows before the next one.
const int _makeAppStepMs = 700;

Future<void> _makeAppRun(void Function(StateDelta) emit) async {
  emit(
    StateDelta(appColor: AppColor.orange, appPhotos: false, appStreak: false),
  );
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: _makeAppStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

Future<void> makeApp(
  State state,
  void Function(StateDelta) emit,
  Labels labels,
) async {
  if (state.tweaking || (state.buildStep >= 1 && state.buildStep <= 4)) return;
  if (state.idea.trim().isEmpty) {
    emit(StateDelta(idea: labels.remindMeToWater, appKind: AppKind.plants));
  }
  await _makeAppRun(emit);
}

void main() {
  test('makeApp walks the four steps, then is ready', () async {
    final s = await app.makeApp(
      sample(idea: 'Plant tracker', appColor: AppColor.blue, appPhotos: true),
    );
    expect(s.buildStep, 5);
    expect(s.appColor, AppColor.orange);
    expect(s.appPhotos, isFalse);
    expect(s.appKind, AppKind.custom);
  });

  test('makeApp fills an empty idea with the plants one', () async {
    final s = await app.makeApp(sample());
    expect(s.idea, 'Remind me to water my plants');
    expect(s.appKind, AppKind.plants);
  });

  test('makeApp does nothing while a build is running', () async {
    await app.makeApp(sample(buildStep: 2));
    expect(app.emitted, isEmpty);
  });
}

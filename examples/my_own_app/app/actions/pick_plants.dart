// pickPlants: Fills the studio idea with the plants prompt and runs the demo.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/labels.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long each build step shows before the next one.
const int _pickPlantsStepMs = 700;

Future<void> _pickPlantsRun(void Function(StateDelta) emit) async {
  emit(
    StateDelta(appColor: AppColor.orange, appPhotos: false, appStreak: false),
  );
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: _pickPlantsStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

Future<void> pickPlants(
  State state,
  void Function(StateDelta) emit,
  Labels labels,
) async {
  if (state.tweaking || (state.buildStep >= 1 && state.buildStep <= 4)) return;
  emit(StateDelta(idea: labels.remindMeToWater, appKind: AppKind.plants));
  await _pickPlantsRun(emit);
}

void main() {
  test('pickPlants fills the idea and builds', () async {
    final s = await app.pickPlants(sample());
    expect(s.idea, 'Remind me to water my plants');
    expect(s.appKind, AppKind.plants);
    expect(s.buildStep, 5);
  });
}

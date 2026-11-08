// pickHabits: Fills the studio idea with the habit-tracker prompt and runs the demo.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/labels.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long each build step shows before the next one.
const int _pickHabitsStepMs = 700;

Future<void> _pickHabitsRun(void Function(StateDelta) emit) async {
  emit(
    StateDelta(appColor: AppColor.orange, appPhotos: false, appStreak: false),
  );
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: _pickHabitsStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

Future<void> pickHabits(
  State state,
  void Function(StateDelta) emit,
  Labels labels,
) async {
  if (state.tweaking || (state.buildStep >= 1 && state.buildStep <= 4)) return;
  emit(StateDelta(idea: labels.trackMyDailyHabits, appKind: AppKind.habits));
  await _pickHabitsRun(emit);
}

void main() {
  test('pickHabits fills the idea and builds', () async {
    final s = await app.pickHabits(sample());
    expect(s.idea, 'Track my daily habits');
    expect(s.appKind, AppKind.habits);
    expect(s.buildStep, 5);
  });
}

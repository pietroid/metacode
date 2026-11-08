// pickMeals: Fills the studio idea with the meal-planner prompt and runs the demo.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/labels.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long each build step shows before the next one.
const int _pickMealsStepMs = 700;

Future<void> _pickMealsRun(void Function(StateDelta) emit) async {
  emit(
    StateDelta(appColor: AppColor.orange, appPhotos: false, appStreak: false),
  );
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: _pickMealsStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

Future<void> pickMeals(
  State state,
  void Function(StateDelta) emit,
  Labels labels,
) async {
  if (state.tweaking || (state.buildStep >= 1 && state.buildStep <= 4)) return;
  emit(StateDelta(idea: labels.planMealsForThe, appKind: AppKind.meals));
  await _pickMealsRun(emit);
}

void main() {
  test('pickMeals fills the idea and builds', () async {
    final s = await app.pickMeals(sample());
    expect(s.idea, 'Plan meals for the week');
    expect(s.appKind, AppKind.meals);
    expect(s.buildStep, 5);
  });
}

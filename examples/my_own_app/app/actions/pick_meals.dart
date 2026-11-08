// pickMeals fills the idea field with the meal-planner prompt and runs the demo.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long each build step shows before the next one.
const int _pickMealsBuildStepMs = 700;

Future<void> _pickMealsRunBuild(void Function(StateDelta) emit) async {
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: _pickMealsBuildStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

Future<void> _pickMealsPickIdea(
  State state,
  void Function(StateDelta) emit,
  String idea,
) async {
  if (state.buildStep >= 1 && state.buildStep <= 4) return;
  emit(StateDelta(idea: idea));
  await _pickMealsRunBuild(emit);
}

Future<void> pickMeals(State state, void Function(StateDelta) emit) async =>
    _pickMealsPickIdea(state, emit, 'Plan meals for the week');

void main() {
  test('pickMeals fills the meal idea and builds', () async {
    final s = await app.pickMeals(sample());
    expect(s.idea, 'Plan meals for the week');
    expect(s.buildStep, 5);
  });
}

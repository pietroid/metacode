// pickHabits: Fills the idea field with the habit-tracker prompt and runs the demo.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long each build step shows before the next one.
const int _pickHabitsBuildStepMs = 700;

Future<void> _pickHabitsRunBuild(void Function(StateDelta) emit) async {
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: _pickHabitsBuildStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

Future<void> _pickHabitsPickIdea(
  State state,
  void Function(StateDelta) emit,
  String idea,
) async {
  if (state.buildStep >= 1 && state.buildStep <= 4) return;
  emit(StateDelta(idea: idea));
  await _pickHabitsRunBuild(emit);
}

Future<void> pickHabits(State state, void Function(StateDelta) emit) async =>
    _pickHabitsPickIdea(state, emit, 'Track my daily habits');

void main() {
  test('pickHabits fills the habit idea and builds', () async {
    final s = await app.pickHabits(sample());
    expect(s.idea, 'Track my daily habits');
    expect(s.buildStep, 5);
  });
}

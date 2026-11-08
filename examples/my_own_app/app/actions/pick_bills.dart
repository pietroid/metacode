// pickBills: Fills the idea field with the bill-splitter prompt and runs the demo.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long each build step shows before the next one.
const int _pickBillsBuildStepMs = 700;

Future<void> _pickBillsRunBuild(void Function(StateDelta) emit) async {
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: _pickBillsBuildStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

Future<void> _pickBillsPickIdea(
  State state,
  void Function(StateDelta) emit,
  String idea,
) async {
  if (state.buildStep >= 1 && state.buildStep <= 4) return;
  emit(StateDelta(idea: idea));
  await _pickBillsRunBuild(emit);
}

Future<void> pickBills(State state, void Function(StateDelta) emit) async =>
    _pickBillsPickIdea(state, emit, 'Split bills with roommates');

void main() {
  test('pickBills fills the bill idea and builds', () async {
    final s = await app.pickBills(sample());
    expect(s.idea, 'Split bills with roommates');
    expect(s.buildStep, 5);
    expect(app.ideaIsBills(s), isTrue);
  });
}

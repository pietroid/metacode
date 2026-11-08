// pickBooks fills the idea field with the book-list prompt and runs the demo.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long each build step shows before the next one.
const int _pickBooksBuildStepMs = 700;

Future<void> _pickBooksRunBuild(void Function(StateDelta) emit) async {
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: _pickBooksBuildStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

Future<void> _pickBooksPickIdea(
  State state,
  void Function(StateDelta) emit,
  String idea,
) async {
  if (state.buildStep >= 1 && state.buildStep <= 4) return;
  emit(StateDelta(idea: idea));
  await _pickBooksRunBuild(emit);
}

Future<void> pickBooks(State state, void Function(StateDelta) emit) async =>
    _pickBooksPickIdea(state, emit, 'Keep my book list');

void main() {
  test('pickBooks fills the book idea and builds', () async {
    final s = await app.pickBooks(sample());
    expect(s.idea, 'Keep my book list');
    expect(s.buildStep, 5);
  });
}

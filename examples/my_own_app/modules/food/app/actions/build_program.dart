// buildProgram: Matches the answers against the program matrix (same goal, honoring the base prefs, closest diet first), shows a short fake processing, then the plan with the best match.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

List<num> _buildProgramMatches(State s) {
  final need = <String>[];
  for (final p in s.prefs) {
    if (p.base && p.selected) need.add(p.key);
  }
  final out = <num>[];
  for (var level = 0; level <= 3; level++) {
    for (var i = 0; i < s.programs.length; i++) {
      final prog = s.programs[i];
      var ok = prog.goal == s.goal && prog.tags.length == level;
      for (final k in need) {
        if (!prog.tags.contains(k)) ok = false;
      }
      if (ok) out.add(i);
    }
  }
  return out;
}

Future<void> buildProgram(State state, void Function(StateDelta) emit) async {
  if (state.goal == Goal.none) return;
  final matches = _buildProgramMatches(state);
  emit(StateDelta(stage: Stage.building, buildStep: 0, matches: matches));
  for (var step = 1; step <= 3; step++) {
    await Future.delayed(Duration(milliseconds: 650));
    emit(StateDelta(buildStep: step));
  }
  await Future.delayed(Duration(milliseconds: 450));
  emit(StateDelta(
    stage: Stage.plan,
    program: matches.isEmpty ? -1 : matches[0],
    deck: [],
    deckPos: 0,
    picked: [],
    shopping: [],
  ));
}

void main() {
  test('buildProgram', () async {
    final omni = await app.buildProgram(sample(goal: Goal.hypertrophy));
    expect(omni.stage, Stage.plan);
    expect(omni.matches, [4, 5, 6, 7]);
    expect(omni.program, 4);
    final vegan = await app.buildProgram(sample(goal: Goal.lowCarb, prefs: ['vegan', 'glutenFree']));
    expect(vegan.matches, [3]);
    final pesc = await app.buildProgram(sample(goal: Goal.weightLoss, prefs: ['pescatarian']));
    expect(pesc.matches, [9, 10, 11]);
  });
}

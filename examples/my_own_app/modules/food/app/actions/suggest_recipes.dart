// suggestRecipes: Deals a deck of recipes for the program's goal that satisfy every selected pref and the program's diet, closest diet first, a few more than the days asked for, and opens the swipe.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> suggestRecipes(State state, void Function(StateDelta) emit) async {
  if (state.program < 0) return;
  final prog = state.programs[state.program.toInt()];
  final need = <String>[];
  for (final p in state.prefs) {
    if (p.selected) need.add(p.key);
  }
  for (final t in prog.tags) {
    need.add(t);
  }
  final base = ['vegan', 'vegetarian', 'pescatarian'];
  final deck = <num>[];
  for (var gap = 0; gap <= 3; gap++) {
    for (var i = 0; i < state.recipes.length; i++) {
      final r = state.recipes[i];
      var ok = r.goals.contains(prog.goal) && deck.length < state.days + 3;
      for (final k in need) {
        if (!r.tags.contains(k)) ok = false;
      }
      var level = 0;
      for (final b in base) {
        if (r.tags.contains(b)) level++;
      }
      final d = level - prog.tags.length;
      if (ok && (d < 0 ? 0 - d : d) == gap) deck.add(i);
    }
  }
  emit(StateDelta(stage: Stage.swipe, deck: deck, deckPos: 0, picked: []));
}

void main() {
  test('suggestRecipes', () async {
    final s = await app.suggestRecipes(sample(goal: Goal.weightLoss, program: 8));
    expect(s.stage, Stage.swipe);
    expect(s.deck.length, 8);
    expect(s.deck.first, 18); // turkey wraps: an omnivore program starts with meat
    final v = await app.suggestRecipes(sample(goal: Goal.lowCarb, program: 3, prefs: ['vegan', 'nutFree']));
    expect(v.deck, [0, 2, 6, 7]);
  });
}

// dealDeck: The recipe deck for the program: recipes for its goal that satisfy every selected pref and the program's diet, closest diet first, a few more than the days asked for.
import '../../../.generated/state.dart';

List<num> dealDeck(State state) {
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
  return deck;
}

// sample: test fixtures. `app` runs actions and values like the engine;
// `sample(...)` is the initial state (the synthetic data in app.yaml) with
// the onboarding answered as given.
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

/// Runs actions and values through the compiled program, like the engine.
final app = TestApp();

/// The initial state with [prefs] selected (by key), [goal] picked and,
/// when [program] is given, that program chosen on the plan screen.
State sample({
  List<String> prefs = const [],
  Goal goal = Goal.none,
  int program = -1,
  num budget = 300,
  Stage stage = Stage.budget,
}) {
  final s = app.initialState;
  for (final p in s.prefs) {
    p.selected = prefs.contains(p.key);
  }
  return s.copyWith(goal: goal, program: program, budget: budget, stage: stage);
}

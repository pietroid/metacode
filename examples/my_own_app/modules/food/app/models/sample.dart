// sample: test fixtures. `app` runs actions and values like the engine;
// `sample(...)` builds a State (every field has a default).
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

/// Runs actions and values through the compiled program, like the engine.
final app = TestApp();

/// A small state to start tests from.
State sample({List<Food>? foods}) => State(
  calorieGoal: 1000,
  foods:
      foods ??
      [
        Food(name: 'Oats', kcal: 300, protein: 10, count: 0),
        Food(name: 'Chicken', kcal: 400, protein: 40, count: 0),
      ],
);

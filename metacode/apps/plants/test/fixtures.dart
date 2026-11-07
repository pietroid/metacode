import '../generated/state.dart';
import '../generated/test_app.dart';

/// Runs actions and relations through the compiled program, like the engine.
final app = TestApp();

/// A small state to start tests from.
State sample({List<Plant>? plants}) => State(
      plants: plants ??
          [
            Plant(name: 'Basil', everyDays: 3, daysLeft: 0),
            Plant(name: 'Cactus', everyDays: 14, daysLeft: 2),
          ],
    );

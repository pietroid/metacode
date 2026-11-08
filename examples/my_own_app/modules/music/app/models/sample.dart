// sample: test fixtures. `app` runs actions and values like the engine;
// `sample(...)` builds a State (every field has a default).
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

/// Runs actions and values through the compiled program, like the engine.
final app = TestApp();

/// A small state to start tests from.
State sample({List<Chord>? chords, num practiceMinutes = 0}) => State(
  chords:
      chords ??
      [
        Chord(name: 'Em', fingers: 'two fingers', learned: true),
        Chord(name: 'G', fingers: 'three fingers', learned: false),
      ],
  practiceMinutes: practiceMinutes,
);

import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

/// Runs actions and relations through the compiled program, like the engine.
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

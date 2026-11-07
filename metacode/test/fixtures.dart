import '../generated/state.dart';
import '../generated/test_app.dart';

/// Runs actions and relations through the compiled program, like the engine.
final app = TestApp();

/// A small state to start tests from.
State sample({
  String idea = '',
  num buildStep = 0,
  String email = '',
  WaitlistStatus waitlistStatus = WaitlistStatus.idle,
  num waitlistCount = 1284,
  num exampleIndex = 0,
}) =>
    State(
      idea: idea,
      buildStep: buildStep,
      email: email,
      waitlistStatus: waitlistStatus,
      waitlistCount: waitlistCount,
      exampleIndex: exampleIndex,
    );

// sample: test fixtures. `app` runs actions and values like the engine;
// `sample(...)` builds a State (every field has a default).
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

/// Runs actions and values through the compiled program, like the engine.
final app = TestApp();

/// A small state to start tests from.
State sample({
  String idea = '',
  AppKind appKind = AppKind.custom,
  num buildStep = 0,
  AppColor appColor = AppColor.orange,
  bool appPhotos = false,
  bool appStreak = false,
  bool tweaking = false,
  String email = '',
  WaitlistStatus waitlistStatus = WaitlistStatus.idle,
  num waitlistCount = 1284,
  num exampleIndex = 0,
}) => State(
  idea: idea,
  appKind: appKind,
  buildStep: buildStep,
  appColor: appColor,
  appPhotos: appPhotos,
  appStreak: appStreak,
  tweaking: tweaking,
  email: email,
  waitlistStatus: waitlistStatus,
  waitlistCount: waitlistCount,
  exampleIndex: exampleIndex,
);

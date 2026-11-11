// sample: test fixtures. `app` runs actions and values like the engine;
// `sample()` is the initial state (app.yaml's draft).
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

final app = TestApp();

State sample() => app.initialState;

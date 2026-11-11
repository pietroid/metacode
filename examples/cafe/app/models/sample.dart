// sample: test fixtures. `app` runs actions and values through the compiled
// program, like the engine. `sample()` is the initial state from app.yaml;
// `sample({'field': value})` changes fields, written as JSON (as in app.yaml).
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

final app = TestApp();

State sample([Map<String, dynamic> changes = const {}]) =>
    State.fromJson({...app.initialState.toJson(), ...changes});

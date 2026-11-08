// sample: test fixtures.
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

final app = TestApp();

State sample({int count = 0, bool started = false}) =>
    State(count: count, started: started);

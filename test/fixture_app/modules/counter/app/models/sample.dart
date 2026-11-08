// sample: test fixtures.
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

final app = TestApp();

State sample({int taps = 0}) => State(taps: taps);

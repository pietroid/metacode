// isTweaking: Whether a studio tweak is being applied right now.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool isTweaking(State state) => state.tweaking;

void main() {
  test('isTweaking', () {
    expect(app.isTweaking(sample(tweaking: true)), isTrue);
  });
}

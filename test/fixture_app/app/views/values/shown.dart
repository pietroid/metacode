// shown: 1 while the count is 1, else 0: the typed text's opacity and
// reveal. Animated: eases up, drops at once (reverseMs: 0).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 100, curve: 'linear', reverseMs: 0)
double shown(State state) => state.count == 1 ? 1.0 : 0.0;

void main() {
  test('shown on a count of 1', () {
    expect(app.shown(sample(count: 1)), 1.0);
    expect(app.shown(sample()), 0.0);
  });
}

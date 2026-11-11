// parityIcon: An icon name from a value: check while the count is odd,
// else close (Parity's icon).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String parityIcon(State state) => state.count.round().isOdd ? 'check' : 'close';

void main() {
  test('parityIcon', () {
    expect(app.parityIcon(sample(count: 3)), 'check');
    expect(app.parityIcon(sample()), 'close');
  });
}

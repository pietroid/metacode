// isOdd: Whether the count is odd: picks Odd or Even (an `if` that fades).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool isOdd(State state) => state.count.round().isOdd;

void main() {
  test('isOdd', () {
    expect(app.isOdd(sample(count: 3)), true);
    expect(app.isOdd(sample(count: 2)), false);
  });
}

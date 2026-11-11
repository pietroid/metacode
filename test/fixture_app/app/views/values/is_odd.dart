// isOdd: Whether the count is odd: picks Odd or Even (an `if` that fades).
// It reads the count through the shared countOf, given the whole state.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/count_of.dart';

bool isOdd(State state) {
  final n = countOf(state);
  return n.isOdd;
}

void main() {
  test('isOdd', () {
    expect(app.isOdd(sample(count: 3)), true);
    expect(app.isOdd(sample(count: 2)), false);
  });
}

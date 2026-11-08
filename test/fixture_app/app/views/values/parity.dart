// parity: Odd or Even, for the count.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String parity(State state, Labels labels) =>
    state.count.round().isOdd ? labels.odd : labels.even;

void main() {
  test('parity', () {
    expect(app.parity(sample(count: 3)), 'Odd');
    expect(app.parity(sample(count: 2)), 'Even');
  });
}

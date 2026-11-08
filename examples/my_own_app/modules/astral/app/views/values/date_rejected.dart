// dateRejected: Whether the last reveal was refused for a missing or impossible date (the form shows why).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool dateRejected(State state) => state.dateInvalid;

void main() {
  test('dateRejected', () {
    expect(app.dateRejected(sample(dateInvalid: true)), true);
    expect(app.dateRejected(sample()), false);
  });
}

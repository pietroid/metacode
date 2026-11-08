// birthMonthValue: The birth month picked in the month dropdown ('1' to '12'), or none yet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String? birthMonthValue(State state) {
  if (state.birthMonth == '') return null;
  return state.birthMonth;
}

void main() {
  test('birthMonthValue', () {
    expect(app.birthMonthValue(sample()), '8');
    expect(app.birthMonthValue(sample(birthMonth: '')), null);
  });
}

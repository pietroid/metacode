// birthDayValue: The birth day picked in the day dropdown, or none yet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String? birthDayValue(State state) {
  if (state.birthDay == '') return null;
  return state.birthDay;
}

void main() {
  test('birthDayValue', () {
    expect(app.birthDayValue(sample()), '12');
    expect(app.birthDayValue(sample(birthDay: '')), null);
  });
}

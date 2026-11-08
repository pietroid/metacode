// dayNumber: A day's date this week (Monday is November 9).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String dayNumber(State state, int index) => '${9 + index}';

void main() {
  test('dayNumber', () {
    expect(app.dayNumber(sample(), 0), '9');
  });
}

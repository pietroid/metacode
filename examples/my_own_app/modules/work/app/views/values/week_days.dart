// weekDays: The seven days of the week strip, 0 (Monday) to 6.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<int> weekDays(State state) => [0, 1, 2, 3, 4, 5, 6];

void main() {
  test('weekDays', () {
    expect(app.weekDays(sample()).length, 7);
  });
}

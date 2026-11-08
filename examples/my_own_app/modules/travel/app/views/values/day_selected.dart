// daySelected: Whether a day is the selected one.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool daySelected(State state, int index) => state.dayIndex.round() == index;

void main() {
  test('daySelected', () {
    expect(app.daySelected(sample(dayIndex: 1), 1), isTrue);
  });
}

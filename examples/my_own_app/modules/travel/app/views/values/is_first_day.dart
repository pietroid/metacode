// isFirstDay: Whether the first day is selected (no previous day).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool isFirstDay(State state) => state.dayIndex.round() <= 0;

void main() {
  test('isFirstDay', () {
    expect(app.isFirstDay(sample()), isTrue);
  });
}

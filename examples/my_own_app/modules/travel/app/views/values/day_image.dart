// dayImage: The selected day's photo of the place.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_day.dart';

String dayImage(State state) => currentDay(state).image;

void main() {
  test('dayImage', () {
    expect(app.dayImage(sample(dayIndex: 1)), 'porto.jpg');
  });
}

// wheelImage: The chart wheel picture of the birth day's week.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_chart.dart';

String wheelImage(State state) => currentChart(state).wheel;

void main() {
  test('wheelImage picks the week', () {
    expect(app.wheelImage(sample(birthDay: '3')), 'w0.webp');
    expect(app.wheelImage(sample(birthDay: '30')), 'w3.webp');
  });
}

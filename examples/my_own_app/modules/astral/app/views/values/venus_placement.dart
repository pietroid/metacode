// venusPlacement: Venus's sign in the week's chart.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_chart.dart';
import 'shared/placement_name.dart';

String venusPlacement(State state, Labels labels) => placementName(state, currentChart(state).venus, labels);

void main() {
  test('venusPlacement', () {
    expect(app.venusPlacement(sample()), 'Virgo');
  });
}

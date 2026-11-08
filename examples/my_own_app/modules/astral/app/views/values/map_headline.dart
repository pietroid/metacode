// mapHeadline: The map's title: the sun and moon signs ("Sun in Leo · Moon in Aquarius").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_chart.dart';
import 'shared/placement_name.dart';

String mapHeadline(State state, Labels labels) =>
    '${labels.sunIn} ${placementName(state, 0, labels)} · ${labels.moonIn} ${placementName(state, currentChart(state).moon, labels)}';

void main() {
  test('mapHeadline', () {
    // Aug 12: Leo, week 2 (moon 2 signs on: Libra).
    expect(app.mapHeadline(sample()), 'Sun in Leo · Moon in Libra');
  });
}

// shownCostLabel: What the cost bar's first figure covers: this day, or this day's transport or attractions when filtered.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String shownCostLabel(State state, Labels labels) {
  if (state.filter == ProgramFilter.transport) return labels.transportToday;
  if (state.filter == ProgramFilter.attraction) return labels.attractionsToday;
  return labels.thisDay;
}

void main() {
  test('shownCostLabel', () {
    expect(app.shownCostLabel(sample()), 'This day');
    expect(app.shownCostLabel(sample(filter: ProgramFilter.transport)), 'Transport');
  });
}

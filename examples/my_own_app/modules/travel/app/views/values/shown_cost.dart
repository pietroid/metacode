// shownCost: The cost bar's first figure: the visible plans, plus food when nothing is filtered out.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_day.dart';
import 'shared/visible_programs.dart';
import 'shared/euros.dart';

String shownCost(State state, Labels labels) {
  num total = 0;
  if (state.filter == ProgramFilter.all) total = currentDay(state).food;
  for (final p in visiblePrograms(state)) {
    total += p.cost;
  }
  return euros(total, labels);
}

void main() {
  test('shownCost', () {
    expect(app.shownCost(sample()), '€65');
    expect(app.shownCost(sample(filter: ProgramFilter.attraction)), '€20');
  });
}

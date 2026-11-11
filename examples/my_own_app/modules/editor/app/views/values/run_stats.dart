// runStats: The last Claude run as one line: its cost, time and turns, and
// the total spent in this editor (empty before the first run).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String runStats(State state) {
  if (state.runMs == 0) return '';
  final seconds = (state.runMs / 1000).toStringAsFixed(1);
  return '\$${state.runCost.toStringAsFixed(3)} · ${seconds}s · '
      '${state.runTurns} turns · total \$${state.totalCost.toStringAsFixed(3)}';
}

void main() {
  test('runStats shows cost, time, turns and total', () {
    expect(app.runStats(sample()), '');
    final state = app.initialState.copyWith(
        runCost: 0.1234, runMs: 41500, runTurns: 7, totalCost: 0.5);
    expect(app.runStats(state), '\$0.123 · 41.5s · 7 turns · total \$0.500');
  });
}

// elementAmount: How much of the week's chart is element [index] (0 fire,
// 1 earth, 2 air, 3 water), 0 to 1.
import '../../../../.generated/state.dart';
import 'current_chart.dart';

double elementAmount(State state, int index) {
  final chart = currentChart(state);
  if (index == 0) return chart.fire.toDouble();
  if (index == 1) return chart.earth.toDouble();
  if (index == 2) return chart.air.toDouble();
  return chart.water.toDouble();
}

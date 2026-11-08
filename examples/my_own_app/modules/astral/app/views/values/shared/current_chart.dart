// currentChart: The mocked chart of the birth day's week of the month.
import '../../../../.generated/state.dart';
import 'week_of_month.dart';

AstralChart currentChart(State state) => state.charts[weekOfMonth(state)];

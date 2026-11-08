// weekOfMonth: Which week of the month the birth day falls in, 0 to 3
// (days 1-7, 8-14, 15-21, 22-31): it picks the mocked chart.
import '../../../../.generated/state.dart';
import 'birth_numbers.dart';

int weekOfMonth(State state) {
  final day = birthNumbers(state).$1;
  if (day <= 7) return 0;
  if (day <= 14) return 1;
  if (day <= 21) return 2;
  return 3;
}

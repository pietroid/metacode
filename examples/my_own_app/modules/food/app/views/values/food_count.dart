// foodCount: The current serving count of a food item.
import '../../../.generated/state.dart';

String foodCount(State state, int index) =>
    '${state.foods[index].count.round()}';

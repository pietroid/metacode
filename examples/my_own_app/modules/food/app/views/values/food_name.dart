// foodName: Returns the name of a food item for the list.
import '../../../.generated/state.dart';

String foodName(State state, int index) => state.foods[index].name;

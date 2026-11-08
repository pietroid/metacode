// exampleIsFood: Whether the food example is currently selected.
import '../../../.generated/state.dart';

bool exampleIsFood(State state) => state.exampleIndex.round() == 0;

// exampleIsTravel: Whether the travel example is currently selected.
import '../../../.generated/state.dart';

bool exampleIsTravel(State state) => state.exampleIndex.round() == 2;

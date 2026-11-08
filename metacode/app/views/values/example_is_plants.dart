// exampleIsPlants: Whether the plants example is currently selected.
import '../../../.generated/state.dart';

bool exampleIsPlants(State state) => state.exampleIndex.round() == 3;

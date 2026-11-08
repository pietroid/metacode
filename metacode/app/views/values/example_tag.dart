// exampleTag: The category tag for the currently visible example.
import '../../../.generated/state.dart';

String exampleTag(State state) {
  final i = state.exampleIndex.round();
  if (i == 1) return 'MUSIC';
  if (i == 2) return 'WORK';
  if (i == 3) return 'HOME';
  return 'FOOD';
}

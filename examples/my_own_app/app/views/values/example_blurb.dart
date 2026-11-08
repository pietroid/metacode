// exampleBlurb: A short description for the currently visible example.
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';

String exampleBlurb(State state, Labels labels) {
  final i = state.exampleIndex.round();
  if (i == 1) return labels.blurbMusic;
  if (i == 2) return labels.blurbWork;
  if (i == 3) return labels.blurbPlants;
  return labels.blurbFood;
}

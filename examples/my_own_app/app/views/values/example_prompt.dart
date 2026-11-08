// examplePrompt: The one-sentence prompt for the currently visible example.
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';

String _examplePromptFor(int i, Labels labels) {
  if (i == 1) return labels.promptWork;
  if (i == 2) return labels.promptTravel;
  return labels.promptFood;
}

String examplePrompt(State state, Labels labels) =>
    '“${_examplePromptFor(state.exampleIndex.round(), labels)}”';

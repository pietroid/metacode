// examplePrompt: What the visitor asked for the currently visible example, in quotes.
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';

String _examplePromptFor(int i, Labels labels) {
  if (i == 1) return labels.promptWork;
  if (i == 2) return labels.promptTravel;
  if (i == 3) return labels.promptAstral;
  return labels.promptFood;
}

String examplePrompt(State state, Labels labels) =>
    '“${_examplePromptFor(state.exampleIndex.round(), labels)}”';

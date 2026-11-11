// canAsk: Whether askClaude can run: a prompt typed and no run going.
import '../../../.generated/state.dart';

bool canAsk(State state) => !state.asking && state.prompt.trim().isNotEmpty;

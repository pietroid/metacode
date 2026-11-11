// lastReply: Why the last call failed (askError), else Claude's last reply.
import '../../../.generated/state.dart';

String lastReply(State state) => state.askError.isNotEmpty ? state.askError : state.runReply;

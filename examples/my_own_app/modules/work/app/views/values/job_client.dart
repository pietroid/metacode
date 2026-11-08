// jobClient: The client name for a job.
import '../../../.generated/state.dart';

String jobClient(State state, int index) => state.jobs[index].client;

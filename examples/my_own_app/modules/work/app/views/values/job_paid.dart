// jobPaid: Whether a job has been paid.
import '../../../.generated/state.dart';

bool jobPaid(State state, int index) => state.jobs[index].paid;

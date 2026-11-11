// tapCount: The taps, as an int (core.modules.counter.tapCount() reads it).
import '../../../.generated/state.dart';

int tapCount(State state) => state.taps.toInt();

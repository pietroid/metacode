// tapsText: The taps, labeled.
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';

String tapsText(State state, Labels labels) =>
    [labels.taps, state.taps.toString()].join(' ');

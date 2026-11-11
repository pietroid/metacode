// doubled: Twice the taps, labeled (the fixture's MainPage shows it as
// counter.doubled).
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';

String doubled(State state, Labels labels) =>
    [labels.doubledText, (state.taps * 2).toString()].join(' ');

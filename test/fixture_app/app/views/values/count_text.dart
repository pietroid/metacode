// countText: The count, labeled.
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';

String countText(State state, Labels labels) =>
    [labels.count, state.count.toString()].join(' ');

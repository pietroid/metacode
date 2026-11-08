// countText: The count, labeled (through the shared withLabel).
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import 'shared/with_label.dart';

String countText(State state, Labels labels) =>
    withLabel(labels.count, state.count);

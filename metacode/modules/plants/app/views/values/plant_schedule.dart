// plantSchedule: How soon a plant needs water again.
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';

String plantSchedule(State state, int index, Labels labels) =>
    '${labels.every} ${state.plants[index].everyDays.round()} ${labels.days}';

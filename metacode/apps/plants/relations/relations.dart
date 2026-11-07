// Relations turn the state into values for the UI.

import '../generated/state.dart';

List<Plant> plantList(State state) => state.plants;

String plantName(State state, int index) => state.plants[index].name;
String plantSchedule(State state, int index) => 'Every ${state.plants[index].everyDays.round()} days';

String plantStatus(State state, int index) {
  final d = state.plants[index].daysLeft.round();
  if (d <= 0) return 'Water today';
  if (d == 1) return 'Tomorrow';
  return 'In $d days';
}

String plantsText(State state) {
  final n = state.plants.where((Plant p) => p.daysLeft <= 0).length;
  if (n == 0) return 'All watered';
  if (n == 1) return '1 plant needs water today';
  return '$n plants need water today';
}

String plantTip(State state) {
  final thirsty = state.plants.where((Plant p) => p.daysLeft <= 0).map((Plant p) => p.name).toList();
  if (thirsty.isNotEmpty) return 'Water ${thirsty.join(' and ')} today.';
  Plant? next;
  for (final p in state.plants) {
    if (next == null || p.daysLeft < next.daysLeft) next = p;
  }
  if (next == null) return 'Add your first plant.';
  final d = next.daysLeft.round();
  return 'All done. Next up: ${next.name} ${d == 1 ? 'tomorrow' : 'in $d days'}.';
}

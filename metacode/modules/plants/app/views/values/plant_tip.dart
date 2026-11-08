// plantTip: A care tip based on the plant with the most urgent need.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String plantTip(State state, Labels labels) {
  final thirsty = state.plants
      .where((Plant p) => p.daysLeft <= 0)
      .map((Plant p) => p.name)
      .toList();
  if (thirsty.isNotEmpty) {
    return '${labels.water} ${thirsty.join(' ${labels.and} ')} ${labels.today}.';
  }
  Plant? next;
  for (final p in state.plants) {
    if (next == null || p.daysLeft < next.daysLeft) next = p;
  }
  if (next == null) return labels.addFirstPlant;
  final d = next.daysLeft.round();
  final when = d == 1
      ? labels.tomorrow.toLowerCase()
      : '${labels.inDays.toLowerCase()} $d ${labels.days}';
  return '${labels.allDoneNextUp} ${next.name} $when.';
}

void main() {
  test('plantTip', () {
    expect(app.plantTip(app.initialState), 'Water Basil today.');
    expect(app.plantTip(sample()), 'Water Basil today.');
    final done = sample(
      plants: [Plant(name: 'Fern', everyDays: 5, daysLeft: 1)],
    );
    expect(app.plantTip(done), 'All done. Next up: Fern tomorrow.');
  });
}

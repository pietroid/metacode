// openNextUp: Opens the section of NextUpCard's item: follow-ups when one is
// overdue, else the to-do list when a task is urgent, else the calendar.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openNextUp(State state, Core core) async {
  for (final f in state.followUps) {
    if (!f.done && f.dueIn < 0) {
      core.navigator.push(Routes.followUps);
      return;
    }
  }
  for (final t in state.tasks) {
    if (!t.done && t.urgent) {
      core.navigator.push(Routes.toDo);
      return;
    }
  }
  core.navigator.push(Routes.calendar);
}

void main() {
  test('openNextUp goes to the overdue follow-up', () async {
    await app.openNextUp(sample());
    expect(app.navigation, ['push followUps']);
  });
}

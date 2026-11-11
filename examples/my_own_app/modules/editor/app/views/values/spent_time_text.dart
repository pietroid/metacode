// spentTimeText: How long Claude has worked on the example app at `index`
// (projectNames) since it was loaded or reset, in minutes, on its ProjectTile.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../actions/shared/project_names.dart';
import '../../models/sample.dart';
import 'shared/format_minutes.dart';
import 'shared/history_of.dart';

String spentTimeText(State state, Labels labels, int index) {
  final names = projectNames();
  final h = historyOf(state, names[index]);
  if (h == null) return '';
  return formatMinutes(h.ms, labels);
}

void main() {
  test('spentTimeText for the current project', () {
    final state = sample().copyWith(
        projectName: 'food', projectMs: 310000, projectTurns: 25);
    expect(app.spentTimeText(state, 0), '5.2 min');
  });
}

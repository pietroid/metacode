// taskPreview: The first open to-do, urgent ones first, for Today.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String taskPreview(State state, Labels labels) {
  for (final t in state.tasks) {
    if (!t.done && t.urgent) return t.title;
  }
  for (final t in state.tasks) {
    if (!t.done) return t.title;
  }
  return labels.allDone;
}

void main() {
  test('taskPreview', () {
    expect(app.taskPreview(sample()), 'Review budget');
    expect(app.taskPreview(sample(tasks: [])), 'All done.');
  });
}

// toggleTask: Marks a to-do done or open.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> toggleTask(
  State state,
  void Function(StateDelta) emit,
  int index,
  bool value,
) async {
  state.tasks[index].done = value;
  emit(StateDelta(tasks: state.tasks));
}

void main() {
  test('toggleTask marks it done', () async {
    final s = await app.toggleTask(sample(), 0, true);
    expect(s.tasks[0].done, isTrue);
  });
}

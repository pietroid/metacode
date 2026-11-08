// toggleJobPaid: Flips whether a job has been paid.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> toggleJobPaid(
  State state,
  void Function(StateDelta) emit,
  int index,
  bool value,
) async {
  state.jobs[index].paid = value;
  emit(StateDelta(jobs: state.jobs));
}

void main() {
  test('toggleJobPaid marks a job as paid', () async {
    final s = await app.toggleJobPaid(sample(), 0, true);
    expect(s.jobs[0].paid, isTrue);
  });
}

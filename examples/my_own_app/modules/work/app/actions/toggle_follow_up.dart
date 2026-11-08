// toggleFollowUp: Closes or reopens a follow-up.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> toggleFollowUp(
  State state,
  void Function(StateDelta) emit,
  int index,
  bool value,
) async {
  state.followUps[index].done = value;
  emit(StateDelta(followUps: state.followUps));
}

void main() {
  test('toggleFollowUp closes it', () async {
    final s = await app.toggleFollowUp(sample(), 0, true);
    expect(s.followUps[0].done, isTrue);
  });
}

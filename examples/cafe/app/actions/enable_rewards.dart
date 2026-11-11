// enableRewards: sets rewardsOn true.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> enableRewards(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(rewardsOn: true));
}

void main() {
  test('enableRewards', () async {
    final s = await app.enableRewards(sample());
    expect(s.rewardsOn, true);
  });
}

// redeemReward: when stars >= the reward's stars, subtracts them and sets
// lastRedeemed to the reward name.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> redeemReward(State state, void Function(StateDelta) emit, int index) async {
  if (index < 0 || index >= state.rewards.length) return;
  final Reward r = state.rewards[index];
  if (state.stars >= r.stars) {
    emit(StateDelta(stars: state.stars - r.stars, lastRedeemed: r.name));
  }
}

void main() {
  test('redeemReward redeems', () async {
    final s = await app.redeemReward(sample(), 0);
    expect(s.stars, 87);
    expect(s.lastRedeemed, 'Extra shot or syrup');
  });
  test('redeemReward refuses when short', () async {
    final s = await app.redeemReward(sample(), 2);
    expect(s.stars, 112);
    expect(s.lastRedeemed, '');
  });
}

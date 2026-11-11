// selectPaidBy: Sets draftPaidBy to currentMembers[index].

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/current_group.dart';

Future<void> selectPaidBy(State state, void Function(StateDelta) emit, int index) async {
  emit(StateDelta(draftPaidBy: currentGroup(state).members[index]));
}

void main() {
  test('selectPaidBy', () async {
    final s = await app.selectPaidBy(sample(), 2);
    expect(s.draftPaidBy, 'Carla');
  });
}

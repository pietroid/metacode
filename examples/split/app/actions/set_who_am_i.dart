// setWhoAmI: Sets my identity in the selected group to currentMembers[index]
// (replacing or adding the identity for selectedGroup).

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/current_group.dart';

Future<void> setWhoAmI(State state, void Function(StateDelta) emit, int index) async {
  final String member = currentGroup(state).members[index];
  final List<Identity> list = [];
  var found = false;
  for (final Identity i in state.identities) {
    if (i.groupId == state.selectedGroup) {
      found = true;
      list.add(Identity(groupId: i.groupId, member: member));
    } else {
      list.add(i);
    }
  }
  if (!found) list.add(Identity(groupId: state.selectedGroup, member: member));
  emit(StateDelta(identities: list));
}

void main() {
  test('setWhoAmI replaces the identity of the group', () async {
    final s = await app.setWhoAmI(sample(), 1);
    expect(s.identities.length, 3);
    expect(s.identities[0].groupId, 'g1');
    expect(s.identities[0].member, 'Ben');
    expect(s.identities[1].groupId, 'g2');
    expect(s.identities[1].member, 'Ana');
  });
}

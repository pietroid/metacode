// myMember: My member name in group groupId from state.identities, else that
// group's first member.

import '../../../../.generated/state.dart';

String myMember(State state, String groupId) {
  for (final Identity i in state.identities) {
    if (i.groupId == groupId) return i.member;
  }
  for (final Group g in state.groups) {
    if (g.id == groupId && g.members.isNotEmpty) return g.members[0];
  }
  return '';
}

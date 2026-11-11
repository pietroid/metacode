// currentMembersText: Member count, members label and the me name, e.g. '4 members · you are Ana'.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/my_member.dart';
import '../../models/sample.dart';

String currentMembersText(State state, Labels labels) {
  final Group g = currentGroup(state);
  final String me = myMember(state, g.id);
  final int n = g.members.length;
  return '$n ${labels.members} · ${labels.youAre} $me';
}

void main() {
  test('currentMembersText', () {
    final t = app.currentMembersText(sample());
    expect(t.contains('4'), true);
    expect(t.contains('Ana'), true);
  });
}

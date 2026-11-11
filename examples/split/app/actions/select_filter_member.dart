// selectFilterMember: Option index 0 (everyone) -> filterMember ''; else
// filterMember = currentMembers[index - 1].

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/current_group.dart';

Future<void> selectFilterMember(State state, void Function(StateDelta) emit, int index) async {
  if (index <= 0) {
    emit(StateDelta(filterMember: ''));
  } else {
    emit(StateDelta(filterMember: currentGroup(state).members[index - 1]));
  }
}

void main() {
  test('selectFilterMember', () async {
    final s = await app.selectFilterMember(sample(), 2);
    expect(s.filterMember, 'Ben');
  });
}

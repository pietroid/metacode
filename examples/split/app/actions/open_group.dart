// openGroup: Sets selectedGroup to groups[index].id, clears filterMember,
// filterCategory and syncError, and pushes the group route.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openGroup(State state, void Function(StateDelta) emit, Core core, int index) async {
  emit(StateDelta(
    selectedGroup: state.groups[index].id,
    filterMember: '',
    filterCategory: '',
    syncError: '',
  ));
  core.navigator.push(Routes.group);
}

void main() {
  test('openGroup selects and pushes', () async {
    final s = await app.openGroup(sample(), 1);
    expect(s.selectedGroup, 'g2');
    expect(app.navigation, ['push group']);
  });
}

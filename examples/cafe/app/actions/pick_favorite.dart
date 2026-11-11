// pickFavorite: sets favoriteStore to index and pops the dialog.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> pickFavorite(State state, void Function(StateDelta) emit, Core core, int index) async {
  emit(StateDelta(favoriteStore: index));
  await core.navigator.pop();
}

void main() {
  test('pickFavorite', () async {
    final s = await app.pickFavorite(sample(), 1);
    expect(s.favoriteStore, 1);
    expect(app.navigation, ['pop']);
  });
}

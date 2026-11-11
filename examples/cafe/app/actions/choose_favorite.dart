// chooseFavorite: sets favoriteStore to index.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> chooseFavorite(State state, void Function(StateDelta) emit, int index) async {
  emit(StateDelta(favoriteStore: index));
}

void main() {
  test('chooseFavorite', () async {
    final s = await app.chooseFavorite(sample(), 2);
    expect(s.favoriteStore, 2);
  });
}

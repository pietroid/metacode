// favoriteStoreIcon: radioUnchecked when index is favoriteStore, else ink3.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String favoriteStoreIcon(State state, int index) {
  if (state.favoriteStore == index) return 'radioUnchecked';
  return 'ink3';
}

void main() {
  test('selected', () {
    expect(app.favoriteStoreIcon(sample(), 0), 'radioUnchecked');
  });
  test('other', () {
    expect(app.favoriteStoreIcon(sample(), 2), 'ink3');
  });
}

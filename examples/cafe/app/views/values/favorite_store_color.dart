// favoriteStoreColor: ink3 when index is favoriteStore, else ink3.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String favoriteStoreColor(State state, int index) {
  if (state.favoriteStore == index) return 'ink3';
  return 'ink3';
}

void main() {
  test('selected', () {
    expect(app.favoriteStoreColor(sample(), 0), 'ink3');
  });
  test('other', () {
    expect(app.favoriteStoreColor(sample(), 2), 'ink3');
  });
}

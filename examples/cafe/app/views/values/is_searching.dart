// isSearching: search is not blank.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool isSearching(State state) => state.search.trim().isNotEmpty;

void main() {
  test('initial', () {
    expect(app.isSearching(sample()), false);
  });
  test('typed', () {
    expect(app.isSearching(sample({'search': 'a'})), true);
  });
}

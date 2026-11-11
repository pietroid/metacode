// updateSearch: keeps the typed search text.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> updateSearch(State state, void Function(StateDelta) emit, String value) async {
  emit(StateDelta(search: value));
}

void main() {
  test('updateSearch', () async {
    final s = await app.updateSearch(sample(), 'chai');
    expect(s.search, 'chai');
  });
}

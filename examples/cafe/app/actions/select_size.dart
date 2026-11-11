// selectSize: sets draftSize to the size at index.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> selectSize(State state, void Function(StateDelta) emit, int index) async {
  const sizes = <DrinkSize>[DrinkSize.small, DrinkSize.medium, DrinkSize.large];
  if (index < 0 || index >= sizes.length) return;
  emit(StateDelta(draftSize: sizes[index]));
}

void main() {
  test('selectSize', () async {
    final s = await app.selectSize(sample(), 2);
    expect(s.draftSize, DrinkSize.large);
  });
}

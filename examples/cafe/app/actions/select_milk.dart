// selectMilk: sets draftMilk to the milk at index.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> selectMilk(State state, void Function(StateDelta) emit, int index) async {
  const milks = <Milk>[Milk.whole, Milk.oat, Milk.almond, Milk.none];
  if (index < 0 || index >= milks.length) return;
  emit(StateDelta(draftMilk: milks[index]));
}

void main() {
  test('selectMilk', () async {
    final s = await app.selectMilk(sample(), 1);
    expect(s.draftMilk, Milk.oat);
  });
}

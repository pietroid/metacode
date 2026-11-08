// selectDay: Picks a day in the week strip (0 = Monday).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> selectDay(
  State state,
  void Function(StateDelta) emit,
  int index,
) async => emit(StateDelta(selectedDay: index));

void main() {
  test('selectDay', () async {
    final s = await app.selectDay(sample(), 3);
    expect(s.selectedDay, 3);
  });
}

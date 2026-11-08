// selectDay: Picks a day of the open trip in the day strip (0 = the first).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> selectDay(
  State state,
  void Function(StateDelta) emit,
  int index,
) async => emit(StateDelta(dayIndex: index));

void main() {
  test('selectDay', () async {
    expect((await app.selectDay(sample(), 1)).dayIndex, 1);
  });
}

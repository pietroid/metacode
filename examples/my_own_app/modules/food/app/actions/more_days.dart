// moreDays: Plans one day more (at most 7).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> moreDays(State state, void Function(StateDelta) emit) async {
  if (state.days < 7) emit(StateDelta(days: state.days + 1));
}

void main() {
  test('moreDays', () async {
    expect((await app.moreDays(sample().copyWith(days: 7))).days, 7);
  });
}

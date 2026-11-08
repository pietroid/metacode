// fewerDays: Plans one day fewer (at least 2).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> fewerDays(State state, void Function(StateDelta) emit) async {
  if (state.days > 2) emit(StateDelta(days: state.days - 1));
}

void main() {
  test('fewerDays', () async {
    expect((await app.fewerDays(sample())).days, 4);
  });
}

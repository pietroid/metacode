// removeShot: draftShots - 1, at least 0.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> removeShot(State state, void Function(StateDelta) emit) async {
  if (state.draftShots.toInt() > 0) emit(StateDelta(draftShots: state.draftShots - 1));
}

void main() {
  test('removeShot', () async {
    expect((await app.removeShot(sample())).draftShots, 0);
    expect((await app.removeShot(sample({'draftShots': 2}))).draftShots, 1);
  });
}

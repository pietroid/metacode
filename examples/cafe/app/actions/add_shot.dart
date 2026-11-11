// addShot: draftShots + 1, at most 3.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> addShot(State state, void Function(StateDelta) emit) async {
  if (state.draftShots.toInt() < 3) emit(StateDelta(draftShots: state.draftShots + 1));
}

void main() {
  test('addShot', () async {
    expect((await app.addShot(sample())).draftShots, 1);
    expect((await app.addShot(sample({'draftShots': 3}))).draftShots, 3);
  });
}

// incQuantity: draftQuantity + 1, at most 20.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> incQuantity(State state, void Function(StateDelta) emit) async {
  if (state.draftQuantity.toInt() < 20) emit(StateDelta(draftQuantity: state.draftQuantity + 1));
}

void main() {
  test('incQuantity', () async {
    expect((await app.incQuantity(sample())).draftQuantity, 2);
    expect((await app.incQuantity(sample({'draftQuantity': 20}))).draftQuantity, 20);
  });
}

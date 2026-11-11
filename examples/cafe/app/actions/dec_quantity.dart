// decQuantity: draftQuantity - 1, at least 1.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> decQuantity(State state, void Function(StateDelta) emit) async {
  if (state.draftQuantity.toInt() > 1) emit(StateDelta(draftQuantity: state.draftQuantity - 1));
}

void main() {
  test('decQuantity', () async {
    expect((await app.decQuantity(sample())).draftQuantity, 1);
    expect((await app.decQuantity(sample({'draftQuantity': 3}))).draftQuantity, 2);
  });
}

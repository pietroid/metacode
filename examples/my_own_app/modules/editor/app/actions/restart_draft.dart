// restartDraft: Starts the running draft over (its state back to its
// app.yaml's): hides it for a moment (draftOn), so it is built anew.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> restartDraft(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(draftOn: false));
  await Future.delayed(const Duration(milliseconds: 120));
  emit(StateDelta(draftOn: true));
}

void main() {
  test('restartDraft shows the draft again', () async {
    final state = await app.restartDraft(sample());
    expect(state.draftOn, isTrue);
  });
}

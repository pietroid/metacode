// setDraftAmount: Keeps the typed amount text and clears formError.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setDraftAmount(State state, void Function(StateDelta) emit, String value) async {
  emit(StateDelta(draftAmount: value, formError: ''));
}

void main() {
  test('setDraftAmount', () async {
    final s = await app.setDraftAmount(sample({'formError': 'x'}), '12.5');
    expect(s.draftAmount, '12.5');
    expect(s.formError, '');
  });
}

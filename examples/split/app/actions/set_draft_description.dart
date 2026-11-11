// setDraftDescription: Keeps the typed description.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setDraftDescription(State state, void Function(StateDelta) emit, String value) async {
  emit(StateDelta(draftDescription: value));
}

void main() {
  test('setDraftDescription', () async {
    final s = await app.setDraftDescription(sample(), 'Taxi');
    expect(s.draftDescription, 'Taxi');
  });
}

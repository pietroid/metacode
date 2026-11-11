// updateName: sets userName to the value.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> updateName(State state, void Function(StateDelta) emit, String value) async {
  emit(StateDelta(userName: value));
}

void main() {
  test('updateName', () async {
    final s = await app.updateName(sample(), 'Sam');
    expect(s.userName, 'Sam');
  });
}

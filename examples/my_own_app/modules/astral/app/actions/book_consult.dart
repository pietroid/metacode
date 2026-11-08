// bookConsult: Books the consultation at the picked time and closes the sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> bookConsult(State state, void Function(StateDelta) emit, Core core) async {
  emit(StateDelta(consultBooked: true));
  await core.navigator.pop();
}

void main() {
  test('bookConsult books and closes', () async {
    final s = await app.bookConsult(sample());
    expect(s.consultBooked, true);
    expect(app.navigation, ['pop']);
  });
}

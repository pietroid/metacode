// showWork: Jumps the carousel to the work example.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showWork(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: 2));

void main() {
  test('showWork jumps to the work slide', () async {
    final s = await app.showWork(sample());
    expect(s.exampleIndex, 2);
  });
}

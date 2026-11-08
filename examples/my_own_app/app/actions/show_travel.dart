// showTravel: Jumps the carousel to the travel example.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showTravel(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: 2));

void main() {
  test('showTravel jumps to the travel slide', () async {
    final s = await app.showTravel(sample());
    expect(s.exampleIndex, 2);
  });
}

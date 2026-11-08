// showMusic: Jumps the carousel to the music example.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showMusic(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: 1));

void main() {
  test('showMusic jumps to the music slide', () async {
    final s = await app.showMusic(sample(exampleIndex: 0));
    expect(s.exampleIndex, 1);
  });
}

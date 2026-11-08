// nextExample advances the examples carousel to the next slide.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

const int _nextExampleExampleCount = 4;

Future<void> nextExample(State state, void Function(StateDelta) emit) async =>
    emit(
      StateDelta(
        exampleIndex: (state.exampleIndex + 1) % _nextExampleExampleCount,
      ),
    );

void main() {
  test('nextExample wraps around from the last slide', () async {
    final s = await app.nextExample(sample(exampleIndex: 3));
    expect(s.exampleIndex, 0);
  });
}

// previousExample: Moves the examples carousel to the previous slide.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

const int _previousExampleExampleCount = 3;

Future<void> previousExample(
  State state,
  void Function(StateDelta) emit,
) async => emit(
  StateDelta(
    exampleIndex:
        (state.exampleIndex + _previousExampleExampleCount - 1) %
        _previousExampleExampleCount,
  ),
);

void main() {
  test('previousExample wraps around from the first slide', () async {
    final s = await app.previousExample(sample(exampleIndex: 0));
    expect(s.exampleIndex, 2);
  });
}

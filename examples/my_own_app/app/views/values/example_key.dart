// exampleKey: The key identifying the currently visible example (food, work,
// travel or astral), which picks its module and phone colors. Astral only when
// the astrology toggle is on; otherwise food.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String exampleKey(State state) {
  final i = state.exampleIndex.round();
  if (i == 1) return 'work';
  if (i == 2) return 'travel';
  if (i == 3 && state.config.astrology) return 'astral';
  return 'food';
}

void main() {
  test('exampleKey', () {
    expect(app.exampleKey(sample(exampleIndex: 1)), 'work');
    expect(app.exampleKey(sample(exampleIndex: 2)), 'travel');
    expect(app.exampleKey(sample(exampleIndex: 3, astrology: true)), 'astral');
    expect(app.exampleKey(sample(exampleIndex: 3)), 'food');
  });
}

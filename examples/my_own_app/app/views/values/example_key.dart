// exampleKey: The key identifying the currently visible example (food, work
// or travel), which picks its module and phone colors.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String exampleKey(State state) {
  final i = state.exampleIndex.round();
  if (i == 1) return 'work';
  if (i == 2) return 'travel';
  return 'food';
}

void main() {
  test('exampleKey', () {
    expect(app.exampleKey(sample(exampleIndex: 1)), 'work');
    expect(app.exampleKey(sample(exampleIndex: 2)), 'travel');
  });
}

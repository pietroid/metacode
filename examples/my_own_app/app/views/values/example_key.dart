// exampleKey: The key identifying the currently visible example.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String exampleKey(State state) {
  final i = state.exampleIndex.round();
  if (i == 1) return 'music';
  if (i == 2) return 'work';
  if (i == 3) return 'plants';
  return 'food';
}

void main() {
  test('exampleKey', () {
    expect(app.exampleKey(sample(exampleIndex: 1)), 'music');
  });
}

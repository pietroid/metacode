// buildReady: Whether the hero demo has reached the ready step.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool buildReady(State state) => state.buildStep >= 5;

void main() {
  test('buildReady', () {
    expect(app.buildReady(sample(buildStep: 5)), isTrue);
  });
}

// buildProgress: How far the fake processing is (0 to 1).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

double buildProgress(State state) => state.buildStep >= 3 ? 1.0 : (state.buildStep / 3).toDouble();

void main() {
  test('buildProgress', () async {
    expect(app.buildProgress(sample().copyWith(buildStep: 3)), 1.0);
  });
}

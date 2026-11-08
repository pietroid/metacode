// buildLines: The processing lines shown so far (one per finished build step).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<num> buildLines(State state) {
  final out = <num>[];
  for (var i = 0; i < state.buildStep && i < 3; i++) {
    out.add(i);
  }
  return out;
}

void main() {
  test('buildLines', () async {
    expect(app.buildLines(sample().copyWith(buildStep: 2)).length, 2);
  });
}

// logPractice: Adds one minute of practice to the daily total.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> logPractice(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(practiceMinutes: state.practiceMinutes + 5));

void main() {
  test('logPractice adds five minutes', () async {
    final s = await app.logPractice(sample(practiceMinutes: 5));
    expect(s.practiceMinutes, 10);
  });
}

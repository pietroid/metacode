// showPlan: Goes back to the plan summary.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showPlan(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(stage: Stage.plan));
}

void main() {
  test('showPlan', () async {
    expect((await app.showPlan(sample())).stage, Stage.plan);
  });
}

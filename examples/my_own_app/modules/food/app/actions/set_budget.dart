// setBudget: Sets the monthly budget from the slider.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setBudget(State state, void Function(StateDelta) emit, double value) async {
  emit(StateDelta(budget: value.round()));
}

void main() {
  test('setBudget', () async {
    expect((await app.setBudget(sample(), 450.4)).budget, 450);
  });
}

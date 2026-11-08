// screen: Which screen MainPage shows (the stage: onboarding, building or plan).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

Stage screen(State state) => state.stage;

void main() {
  test('screen', () async {
    expect(app.screen(sample(stage: Stage.plan)), Stage.plan);
  });
}

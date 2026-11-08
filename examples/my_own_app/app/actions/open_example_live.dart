// openExampleLive: Opens the example shown in the phone on its own page (foodLive, workLive, travelLive or astralLive).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openExampleLive(State state, Core core) async {
  final i = state.exampleIndex.round();
  if (i == 1) {
    core.navigator.push(Routes.workLive);
    return;
  }
  if (i == 2) {
    core.navigator.push(Routes.travelLive);
    return;
  }
  if (i == 3 && state.config.astrology) {
    core.navigator.push(Routes.astralLive);
    return;
  }
  core.navigator.push(Routes.foodLive);
}

void main() {
  test('openExampleLive opens the food page', () async {
    await app.openExampleLive(sample());
    expect(app.navigation, ['push foodLive']);
  });
  test('openExampleLive opens the travel page', () async {
    await app.openExampleLive(sample(exampleIndex: 2));
    expect(app.navigation, ['push travelLive']);
  });
  test('openExampleLive opens the astral page', () async {
    await app.openExampleLive(sample(exampleIndex: 3, astrology: true));
    expect(app.navigation, ['push astralLive']);
  });
}

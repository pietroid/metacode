// makeApp: Runs the live "build your app" demo on the hero card.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long each build step shows before the next one.
const int _makeAppBuildStepMs = 700;

Future<void> _makeAppRunBuild(void Function(StateDelta) emit) async {
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: _makeAppBuildStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

/// Walks the four build steps, then shows "Your app is ready".
Future<void> makeApp(State state, void Function(StateDelta) emit) async {
  if (state.buildStep >= 1 && state.buildStep <= 4) return;
  await _makeAppRunBuild(emit);
}

void main() {
  test('makeApp walks the four steps, then is ready', () async {
    final s = await app.makeApp(sample(idea: 'Plant tracker'));
    expect(s.buildStep, 5);
    expect(app.emitted, [
      {'buildStep': 1},
      {'buildStep': 2},
      {'buildStep': 3},
      {'buildStep': 4},
      {'buildStep': 5},
    ]);
  });

  test('makeApp does nothing while a build is running', () async {
    await app.makeApp(sample(buildStep: 2));
    expect(app.emitted, isEmpty);
  });
}

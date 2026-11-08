// markStarted: The app's start action (app.yaml `start:`): records that it
// ran.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> markStarted(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(started: true));

void main() {
  test('markStarted records the start', () async {
    expect((await app.markStarted(sample())).started, true);
  });
}

// updateIdea: Updates the hero idea field as the user types.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> updateIdea(
  State state,
  void Function(StateDelta) emit,
  String value,
) async => emit(StateDelta(idea: value, buildStep: 0));

void main() {
  test('updateIdea sets the idea and resets the demo', () async {
    final s = await app.updateIdea(sample(buildStep: 5), 'Plant tracker');
    expect(s.idea, 'Plant tracker');
    expect(s.buildStep, 0);
  });
}

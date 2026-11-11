// setPrompt: Keeps what the user types for Claude.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setPrompt(
    State state, void Function(StateDelta) emit, String value) async {
  emit(StateDelta(prompt: value));
}

void main() {
  test('setPrompt keeps the text', () async {
    final state = await app.setPrompt(sample(), 'make it blue');
    expect(state.prompt, 'make it blue');
  });
}

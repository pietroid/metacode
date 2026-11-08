// showExample: Jumps the carousel to example [index] (0 food, 1 work,
// 2 travel, 3 astral) and plays its chat (see playChat): what an ExampleChip runs
// when tapped.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/play_chat.dart';

Future<void> showExample(
    State state, void Function(StateDelta) emit, int index) async {
  // Switched and cleared together, so the old text never shows the new one.
  emit(StateDelta(exampleIndex: index, chatStage: 0));
  await playChat(emit);
}

void main() {
  test('showExample jumps to the tapped example and plays it', () async {
    final s = await app.showExample(sample(chatStage: 2), 2);
    expect(s.exampleIndex, 2);
    expect(s.chatStage, 2);
  });
}

// playExample: The app's start action (app.yaml `start:`): plays the
// current example's chat from the beginning (see playChat).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/play_chat.dart';

Future<void> playExample(State state, void Function(StateDelta) emit) =>
    playChat(emit);

void main() {
  test('playExample ends with the whole chat shown', () async {
    final s = await app.playExample(sample(chatStage: 2));
    expect(s.chatStage, 2);
  });
}

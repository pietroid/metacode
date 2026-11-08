// chatOpacity: The example chat card's opacity: hidden at stage 0 (switching examples), shown from stage 1. Fades in, and out faster.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 300, curve: 'easeOut', reverseMs: 150)
double chatOpacity(State state) => state.chatStage >= 1 ? 1.0 : 0.0;

void main() {
  test('chatOpacity follows the chat stage', () {
    expect(app.chatOpacity(sample(chatStage: 1)), 1.0);
    expect(app.chatOpacity(sample()), 0.0);
  });
}

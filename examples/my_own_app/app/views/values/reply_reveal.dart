// replyReveal: How much of the assistant's answer shows: typed out at stage 2, after the question, cleared at once when the chat restarts.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 1800, curve: 'linear', reverseMs: 0)
double replyReveal(State state) => state.chatStage >= 2 ? 1.0 : 0.0;

void main() {
  test('replyReveal follows the chat stage', () {
    expect(app.replyReveal(sample(chatStage: 2)), 1.0);
    expect(app.replyReveal(sample(chatStage: 1)), 0.0);
  });
}

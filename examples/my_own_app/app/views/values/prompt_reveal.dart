// promptReveal: How much of the visitor's question shows: typed out from stage 1, cleared at once when the chat restarts.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 1100, curve: 'linear', reverseMs: 0)
double promptReveal(State state) => state.chatStage >= 1 ? 1.0 : 0.0;

void main() {
  test('promptReveal follows the chat stage', () {
    expect(app.promptReveal(sample(chatStage: 1)), 1.0);
    expect(app.promptReveal(sample()), 0.0);
  });
}

// followUpTopic: What a follow-up is about.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String followUpTopic(State state, int index) => state.followUps[index].topic;

void main() {
  test('followUpTopic', () {
    expect(app.followUpTopic(sample(), 0), 'SOW');
  });
}

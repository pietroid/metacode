// makeLikeThis: Copies the current example prompt into the idea field.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/labels.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/example_prompt.dart';

/// Uses the current example's sentence as the idea and opens the waitlist.
Future<void> makeLikeThis(
  State state,
  void Function(StateDelta) emit,
  Core core,
  Labels labels,
) async {
  emit(
    StateDelta(
      idea: examplePrompt(
        state,
        labels,
      ).replaceAll('“', '').replaceAll('”', ''),
      buildStep: 0,
    ),
  );
  core.navigator.push(Routes.waitlist);
}

void main() {
  test('makeLikeThis sets the idea and opens the waitlist', () async {
    final s = await app.makeLikeThis(sample(exampleIndex: 1));
    expect(s.idea, 'Teach me guitar, ten minutes a day');
    expect(app.navigation, ['push waitlist']);
  });
}

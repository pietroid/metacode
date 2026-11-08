// ideaSummary: A shortened version of the current idea for the waitlist sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String ideaSummary(State state, Labels labels) {
  final idea = state.idea.trim();
  if (idea.isEmpty) return labels.ideaSummaryEmpty;
  return '${labels.yourFirstApp} "$idea". ${labels.readyWhenYouGetIn}';
}

void main() {
  test('ideaSummary', () {
    expect(
      app.ideaSummary(sample(idea: 'Plant tracker')),
      contains('Plant tracker'),
    );
  });
}

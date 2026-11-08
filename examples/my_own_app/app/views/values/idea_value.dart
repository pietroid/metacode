// ideaValue: The current idea text for the hero text field.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String ideaValue(State state) => state.idea;

void main() {
  test('ideaValue', () {
    expect(app.ideaValue(sample(idea: 'Plant tracker')), 'Plant tracker');
  });
}

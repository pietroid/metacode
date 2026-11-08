// goalBlurb: A goal card's one-line description.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/pick.dart';

String goalBlurb(State state, Labels labels, int index) => pick(labels, state.goalOptions[index].blurb, state.goalOptions[index].blurbPt);

void main() {
  test('goalBlurb', () async {
    expect(app.goalBlurb(sample(), 2), contains('deficit'));
  });
}

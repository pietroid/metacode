// goalName: A goal card's name in the shown language.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/pick.dart';

String goalName(State state, Labels labels, int index) => pick(labels, state.goalOptions[index].name, state.goalOptions[index].namePt);

void main() {
  test('goalName', () async {
    expect(app.goalName(sample(), 1), 'Hypertrophy');
  });
}

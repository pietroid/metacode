// currentTitle: The title of the project in the editor (projectName), for
// EditorPage's app bar.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/title_of.dart';

String currentTitle(State state, Labels labels) =>
    titleOf(labels, state.projectName);

void main() {
  test('currentTitle follows the project', () {
    expect(app.currentTitle(sample()), 'Editor');
    expect(app.currentTitle(sample().copyWith(projectName: 'food')), 'Food');
  });
}

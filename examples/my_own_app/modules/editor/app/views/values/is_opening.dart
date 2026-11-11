// isOpening: Whether the example app at `index` (projectNames) is being
// loaded (openProject), for a spinner on its ProjectTile.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../actions/shared/project_names.dart';
import '../../models/sample.dart';

bool isOpening(State state, int index) {
  final names = projectNames();
  return state.opening == names[index];
}

void main() {
  test('isOpening only for the one loading', () {
    final state = sample().copyWith(opening: 'travel');
    expect(app.isOpening(state, 1), isTrue);
    expect(app.isOpening(state, 0), isFalse);
  });
}

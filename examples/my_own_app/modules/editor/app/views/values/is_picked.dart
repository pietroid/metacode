// isPicked: Whether the draft's buttons use the palette color of the Swatch
// at `index`.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../actions/shared/draft_button.dart';
import '../../actions/shared/file_in.dart';
import '../../actions/shared/palette.dart';
import '../../models/sample.dart';

bool isPicked(State state, int index) {
  final file = fileIn(state.draft, draftButton());
  if (file == null) return false;
  return file.contains(palette()[index]);
}

void main() {
  test('isPicked marks the color the draft uses', () {
    expect(app.isPicked(sample(), 0), isTrue);
    expect(app.isPicked(sample(), 1), isFalse);
  });
}

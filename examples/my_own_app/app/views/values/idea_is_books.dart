// ideaIsBooks: Whether the current idea is the book-list prompt.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool ideaIsBooks(State state) => state.idea == 'Keep my book list';

void main() {
  test('ideaIsBooks', () {
    expect(app.ideaIsBooks(sample(idea: 'Keep my book list')), isTrue);
  });
}

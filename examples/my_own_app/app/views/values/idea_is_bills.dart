// ideaIsBills: Whether the studio idea is the bills chip.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool ideaIsBills(State state) => state.appKind == AppKind.bills;

void main() {
  test('ideaIsBills', () {
    expect(app.ideaIsBills(sample(appKind: AppKind.bills)), isTrue);
    expect(app.ideaIsBills(sample()), isFalse);
  });
}

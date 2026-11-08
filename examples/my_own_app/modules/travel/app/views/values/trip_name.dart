// tripName: A trip's name.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/tr.dart';

String tripName(State state, Labels labels, int index) => tr(state.trips[index].name, labels);

void main() {
  test('tripName', () {
    expect(app.tripName(sample(), 0), 'Portugal');
    app.locale = 'pt_br';
    expect(app.tripName(sample(), 0), 'Portugal PT');
    app.locale = null;
  });
}

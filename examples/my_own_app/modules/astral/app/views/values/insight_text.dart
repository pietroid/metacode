// insightText: Insight [index] (0-2) of the week's chart.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_chart.dart';
import 'shared/tr.dart';

String insightText(State state, Labels labels, int index) =>
    tr(currentChart(state).insights[index], labels);

void main() {
  test('insightText', () {
    expect(app.insightText(sample(), 2), 'C1');
    app.locale = 'pt_br';
    expect(app.insightText(sample(), 0), 'A1 PT');
    app.locale = null;
  });
}

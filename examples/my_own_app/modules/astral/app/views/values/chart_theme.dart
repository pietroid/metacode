// chartTheme: The week's theme, the quote over the insights.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_chart.dart';
import 'shared/tr.dart';

String chartTheme(State state, Labels labels) => tr(currentChart(state).theme, labels);

void main() {
  test('chartTheme', () {
    expect(app.chartTheme(sample()), 'Theme 1');
  });
}

// tripsSummary: How many trips are planned, under the home headline.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String tripsSummary(State state, Labels labels) {
  final trips = state.trips;
  return '${trips.length} ${labels.tripsPlanned}';
}

void main() {
  test('tripsSummary', () {
    expect(app.tripsSummary(sample()), '2 trips planned');
    app.locale = 'pt_br';
    expect(app.tripsSummary(sample()), '2 viagens planejadas');
    app.locale = null;
  });
}

// tripPlaces: The places a trip goes ("Lisbon · Sintra").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/tr.dart';

String tripPlaces(State state, Labels labels, int index) => tr(state.trips[index].places, labels);

void main() {
  test('tripPlaces', () {
    expect(app.tripPlaces(sample(), 0), 'Lisbon · Sintra');
    app.locale = 'pt_br';
    expect(app.tripPlaces(sample(), 0), 'Lisboa · Sintra');
    app.locale = null;
  });
}

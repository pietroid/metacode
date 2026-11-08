// filterIsTransport: Whether the day shows only transport.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool filterIsTransport(State state) => state.filter == ProgramFilter.transport;

void main() {
  test('filterIsTransport', () {
    expect(app.filterIsTransport(sample(filter: ProgramFilter.transport)), isTrue);
  });
}

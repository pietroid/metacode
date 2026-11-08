// showTransport: Shows only the day's transport (trains, flights, buses).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showTransport(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(filter: ProgramFilter.transport));

void main() {
  test('showTransport', () async {
    final s = await app.showTransport(sample(filter: ProgramFilter.transport));
    expect(s.filter, ProgramFilter.transport);
  });
}

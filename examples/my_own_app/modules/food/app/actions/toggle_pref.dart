// togglePref: Selects or clears a food preference card.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> togglePref(State state, void Function(StateDelta) emit, int index) async {
  state.prefs[index].selected = !state.prefs[index].selected;
  emit(StateDelta(prefs: state.prefs));
}

void main() {
  test('togglePref', () async {
    final s = await app.togglePref(sample(), 2);
    expect(s.prefs[2].selected, true);
    expect((await app.togglePref(s, 2)).prefs[2].selected, false);
  });
}

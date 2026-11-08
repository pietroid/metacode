// programTags: The selected prefs as one line, or "eats everything".
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/pick.dart';

String programTags(State state, Labels labels) {
  final names = <String>[];
  for (final p in state.prefs) {
    if (p.selected) names.add(pick(labels, p.name, p.namePt));
  }
  if (names.isEmpty) return labels.noRestrictions;
  return names.join(' · ');
}

void main() {
  test('programTags', () async {
    expect(app.programTags(sample()), 'Eats everything');
    expect(app.programTags(sample(prefs: ['vegan', 'nutFree'])), 'Vegan · Nut-free');
  });
}

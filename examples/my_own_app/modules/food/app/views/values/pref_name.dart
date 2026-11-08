// prefName: A preference card's name in the shown language.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/pick.dart';

String prefName(State state, Labels labels, int index) => pick(labels, state.prefs[index].name, state.prefs[index].namePt);

void main() {
  test('prefName', () async {
    expect(app.prefName(sample(), 0), 'Vegan');
  });
}

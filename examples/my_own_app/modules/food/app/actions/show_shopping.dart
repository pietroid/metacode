// showShopping: Opens the shopping list.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showShopping(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(stage: Stage.shopping));
}

void main() {
  test('showShopping', () async {
    expect((await app.showShopping(sample())).stage, Stage.shopping);
  });
}

// skipOnboarding: sets onboarded true and checkoutStore = favoriteStore.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> skipOnboarding(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(onboarded: true, checkoutStore: state.favoriteStore));
}

void main() {
  test('skipOnboarding', () async {
    final s = await app.skipOnboarding(sample({'favoriteStore': 1}));
    expect(s.onboarded, true);
    expect(s.checkoutStore, 1);
  });
}

// favoriteStoreName: name and address of the favorite store.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String favoriteStoreName(State state) {
  final int i = state.favoriteStore.toInt();
  if (i < 0 || i >= state.stores.length) return '';
  return '${state.stores[i].name} · ${state.stores[i].address}';
}

void main() {
  test('favoriteStoreName', () {
    expect(app.favoriteStoreName(sample()), 'Downtown · 120 Market St');
  });
  test('favoriteStoreName second', () {
    expect(app.favoriteStoreName(sample({'favoriteStore': 1})), 'Riverside · 48 Harbor Way');
  });
}

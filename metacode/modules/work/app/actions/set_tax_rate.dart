// setTaxRate: Updates the tax rate used for the reserve estimate.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setTaxRate(
  State state,
  void Function(StateDelta) emit,
  double value,
) async => emit(StateDelta(taxRate: value.round()));

void main() {
  test('setTaxRate rounds the value', () async {
    final s = await app.setTaxRate(sample(), 20.4);
    expect(s.taxRate, 20);
  });
}

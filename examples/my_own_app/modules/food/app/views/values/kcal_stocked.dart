// kcalStocked: The kcal of the checked shopping items, of the whole list.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/group_digits.dart';
import 'shared/list_kcal.dart';
import 'shared/stocked_kcal.dart';

String kcalStocked(State state, Labels labels) => '${groupDigits(stockedKcal(state), labels.thousandsSep)} ${labels.of} ${groupDigits(listKcal(state), labels.thousandsSep)} ${labels.kcal}';

void main() {
  test('kcalStocked', () async {
    expect(app.kcalStocked(sample().copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false)])), '600 of 800 kcal');
  });
}

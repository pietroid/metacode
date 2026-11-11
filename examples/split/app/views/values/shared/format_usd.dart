// formatUsd: Rounds to cents with a comma thousands separator, no sign, absolute value.

import 'package:flutter_test/flutter_test.dart';

String formatUsd(num amount) {
  final int c = (amount.abs() * 100).round();
  final int whole = c ~/ 100;
  final int cents = c % 100;
  final String s = whole.toString();
  var out = '';
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out += ',';
    out += s[i];
  }
  return '\$$out.${cents.toString().padLeft(2, '0')}';
}

void main() {
  test('formatUsd', () {
    expect(formatUsd(1234.5), '\$1,234.50');
    expect(formatUsd(-0.5), '\$0.50');
    expect(formatUsd(1000000), '\$1,000,000.00');
  });
}

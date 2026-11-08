// groupDigits: Groups the digits of a rounded number with [sep] (1,250 or 1.250).
import 'package:flutter_test/flutter_test.dart';

String groupDigits(num n, String sep) {
  final digits = n.round().toString();
  var out = '';
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += sep;
    out += digits[i];
  }
  return out;
}

void main() {
  test('groupDigits', () {
    expect(groupDigits(1234567, ','), '1,234,567');
    expect(groupDigits(950, '.'), '950');
  });
}

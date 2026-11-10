// looksLikeEmail: Whether a text looks like an email address (something@
// domain.tld, no spaces). Used by joinWaitlist, local and remote.
import 'package:flutter_test/flutter_test.dart';

bool looksLikeEmail(String text) {
  final t = text.trim();
  final at = t.indexOf('@');
  return at > 0 &&
      t.lastIndexOf('.') > at + 1 &&
      !t.endsWith('.') &&
      !t.contains(' ');
}

void main() {
  test('looksLikeEmail', () {
    for (final bad in ['', 'ada', 'ada@', 'ada@site', '@site.com', 'ada@site.', 'a da@b.co']) {
      expect(looksLikeEmail(bad), isFalse, reason: bad);
    }
    expect(looksLikeEmail(' ada@example.com '), isTrue);
  });
}

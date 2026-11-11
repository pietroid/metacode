// profileInitials: initials of the user name (up to 2), or ?.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String profileInitials(State state) {
  final List<String> parts = state.userName.trim().split(' ');
  String out = '';
  for (final String p in parts) {
    if (p.isNotEmpty && out.length < 2) {
      out = out + p[0].toUpperCase();
    }
  }
  if (out.isEmpty) return '?';
  return out;
}

void main() {
  test('profileInitials', () {
    expect(app.profileInitials(sample()), 'AR');
  });
  test('profileInitials blank', () {
    expect(app.profileInitials(sample({'userName': ''})), '?');
  });
}

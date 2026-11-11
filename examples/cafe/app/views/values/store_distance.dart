// storeDistance: Store index 'distance · hours'.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String storeDistance(State state, int index) {
  final Store s = state.stores[index];
  return '${s.distance} · ${s.hours}';
}

void main() {
  test('index 0', () {
    expect(app.storeDistance(sample(), 0), '0.4 mi · 6am - 8pm');
  });
}

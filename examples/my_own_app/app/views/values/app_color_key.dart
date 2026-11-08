// appColorKey: The studio preview app's color as a key (orange, green,
// blue, purple), for the swatches and the colored parts of the preview.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String appColorKey(State state) {
  if (state.appColor == AppColor.green) return 'green';
  if (state.appColor == AppColor.blue) return 'blue';
  if (state.appColor == AppColor.purple) return 'purple';
  return 'orange';
}

void main() {
  test('appColorKey', () {
    expect(app.appColorKey(sample()), 'orange');
    expect(app.appColorKey(sample(appColor: AppColor.purple)), 'purple');
  });
}

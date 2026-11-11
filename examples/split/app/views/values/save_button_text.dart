// saveButtonText: the saving label while saving, else the save label.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String saveButtonText(State state, Labels labels) {
  if (state.saveStatus == SaveStatus.saving) return labels.saving;
  return labels.save;
}

void main() {
  test('saveButtonText', () {
    expect(app.saveButtonText(sample()), 'Save expense');
    expect(app.saveButtonText(sample({'saveStatus': 'saving'})), 'Saving…');
  });
}

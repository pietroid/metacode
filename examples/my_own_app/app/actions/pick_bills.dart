// pickBills: Fills the studio idea with the bill-splitter prompt and runs the demo.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/labels.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

/// How long each build step shows before the next one.
const int _pickBillsStepMs = 700;

Future<void> _pickBillsRun(void Function(StateDelta) emit) async {
  emit(
    StateDelta(appColor: AppColor.orange, appPhotos: false, appStreak: false),
  );
  for (var step = 1; step <= 4; step++) {
    emit(StateDelta(buildStep: step));
    await Future.delayed(Duration(milliseconds: _pickBillsStepMs));
  }
  emit(StateDelta(buildStep: 5));
}

Future<void> pickBills(
  State state,
  void Function(StateDelta) emit,
  Labels labels,
) async {
  if (state.tweaking || (state.buildStep >= 1 && state.buildStep <= 4)) return;
  emit(StateDelta(idea: labels.splitBillsWithRoommates, appKind: AppKind.bills));
  await _pickBillsRun(emit);
}

void main() {
  test('pickBills fills the idea and builds', () async {
    final s = await app.pickBills(sample());
    expect(s.idea, 'Split bills with roommates');
    expect(s.appKind, AppKind.bills);
    expect(s.buildStep, 5);
  });
}

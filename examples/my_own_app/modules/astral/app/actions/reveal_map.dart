// revealMap: Reads the astral map of the picked date, as a little show:
// rejects a missing or impossible date (dateInvalid), else steps
// readingStage 1 (aligning the stars) to 5: the wheel fades in, then the
// placements, the insights type out, and the consult card appears. The
// animated values (wheelOpacity, insightReveal...) draw each stage.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> revealMap(State state, void Function(StateDelta) emit) async {
  if (state.birthDay == '' || state.birthMonth == '') {
    emit(StateDelta(dateInvalid: true));
    return;
  }
  final day = int.parse(state.birthDay);
  final month = int.parse(state.birthMonth);
  final lengths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (day > lengths[month - 1]) {
    emit(StateDelta(dateInvalid: true, readingStage: 0));
    return;
  }
  emit(StateDelta(dateInvalid: false, readingStage: 1));
  await Future.delayed(const Duration(milliseconds: 1600));
  emit(StateDelta(readingStage: 2));
  await Future.delayed(const Duration(milliseconds: 900));
  emit(StateDelta(readingStage: 3));
  await Future.delayed(const Duration(milliseconds: 700));
  emit(StateDelta(readingStage: 4));
  await Future.delayed(const Duration(milliseconds: 1800));
  emit(StateDelta(readingStage: 5));
}

void main() {
  test('revealMap plays every stage for a real date', () async {
    final s = await app.revealMap(sample());
    expect(s.readingStage, 5);
    expect(s.dateInvalid, false);
  });
  test('revealMap rejects a missing date', () async {
    final s = await app.revealMap(sample(birthMonth: ''));
    expect(s.dateInvalid, true);
    expect(s.readingStage, 0);
  });
  test('revealMap rejects February 30', () async {
    final s = await app.revealMap(sample(birthDay: '30', birthMonth: '2'));
    expect(s.dateInvalid, true);
  });
}

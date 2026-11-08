// openTicket: Opens the ticket sheet of a plan in the day's (filtered) list.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/current_day.dart';

Future<void> openTicket(
  State state,
  void Function(StateDelta) emit,
  Core core,
  int index,
) async {
  final all = currentDay(state).programs;
  var seen = 0;
  var real = -1;
  for (var i = 0; i < all.length; i++) {
    final kind = all[i].kind;
    var shown = state.filter == ProgramFilter.all;
    if (state.filter == ProgramFilter.transport) {
      shown = kind == ProgramKind.transport;
    }
    if (state.filter == ProgramFilter.attraction) {
      shown = kind == ProgramKind.attraction;
    }
    if (shown) {
      if (seen == index) real = i;
      seen++;
    }
  }
  if (real < 0) return;
  emit(StateDelta(programIndex: real));
  core.navigator.push(Routes.ticket);
}

void main() {
  test('openTicket maps the filtered row to the day list', () async {
    final s = await app.openTicket(
      sample(filter: ProgramFilter.attraction),
      0,
    );
    expect(s.programIndex, 1);
    expect(app.navigation, ['push ticket']);
  });
}

// altIndexes: The matching programs other than the picked one, as indexes into programs.
import '../../../../.generated/state.dart';

List<num> altIndexes(State s) {
  final out = <num>[];
  for (final m in s.matches) {
    if (m != s.program) out.add(m);
  }
  return out;
}

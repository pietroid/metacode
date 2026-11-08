// spentUsd: What the checked shopping items cost, in USD.
import '../../../../.generated/state.dart';

num spentUsd(State s) {
  num t = 0;
  for (final i in s.shopping) {
    if (i.checked) t += i.price;
  }
  return t;
}

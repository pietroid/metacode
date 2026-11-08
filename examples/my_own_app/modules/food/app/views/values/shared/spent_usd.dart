// spentUsd: What the bought shopping items cost, in USD.
import '../../../../.generated/state.dart';

num spentUsd(State s) {
  num t = 0;
  for (final i in s.shopping) {
    if (i.bought) t += i.price;
  }
  return t;
}

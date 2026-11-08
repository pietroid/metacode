// recipeCost: A recipe's cost in USD: the sum of its ingredients'.
import '../../../../.generated/state.dart';

num recipeCost(Recipe r) {
  num t = 0;
  for (final i in r.ingredients) {
    t += i.price;
  }
  return t;
}

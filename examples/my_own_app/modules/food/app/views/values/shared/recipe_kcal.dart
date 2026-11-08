// recipeKcal: A recipe's kcal: the sum of its ingredients'.
import '../../../../.generated/state.dart';

num recipeKcal(Recipe r) {
  num t = 0;
  for (final i in r.ingredients) {
    t += i.kcal;
  }
  return t;
}

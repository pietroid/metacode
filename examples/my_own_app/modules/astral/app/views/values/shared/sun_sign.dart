// sunSign: The tropical sun sign of the picked birth date, 0 Aries to
// 11 Pisces (each month's sign starts on its cut-off day).
import '../../../../.generated/state.dart';
import 'birth_numbers.dart';

int sunSign(State state) {
  final date = birthNumbers(state);
  final cuts = [20, 19, 21, 20, 21, 21, 23, 23, 23, 23, 22, 22];
  final month = date.$2;
  final starting = (month + 9) % 12;
  if (date.$1 >= cuts[month - 1]) return starting;
  return (starting + 11) % 12;
}

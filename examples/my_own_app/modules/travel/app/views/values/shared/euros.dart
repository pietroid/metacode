// euros: An amount in euros, whole when it is whole ("€20"), else with cents,
// with a decimal comma in Portuguese ("€12,50").
import '../../../../.generated/labels.dart';

String euros(num amount, Labels labels) {
  final whole = amount.round();
  if (whole == amount) return '€$whole';
  final text = amount.toStringAsFixed(2);
  if (labels.locale == 'pt_br') return '€${text.replaceAll('.', ',')}';
  return '€$text';
}

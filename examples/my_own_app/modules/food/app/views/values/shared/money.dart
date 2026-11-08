// money: An amount stored in USD in the shown currency: the labels give the symbol, the fixed synthetic rate and the separators ($3.20, R$ 1.500).
import '../../../../.generated/labels.dart';

String money(num usd, Labels labels) {
  final v = usd * double.parse(labels.currencyRate);
  var body = '';
  if (v < 100) {
    body = v.toStringAsFixed(2).replaceAll('.', labels.decimalSep);
  } else {
    final digits = v.round().toString();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) body += labels.thousandsSep;
      body += digits[i];
    }
  }
  final sym = labels.currencySymbol;
  return sym.length > 1 ? '$sym $body' : '$sym$body';
}

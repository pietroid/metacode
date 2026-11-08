// parseAmount: A typed amount in euros ("20", "12,5", "€ 8"), or 0 when it is
// not a positive number.
num parseAmount(String text) {
  final clean = text.replaceAll('€', '').replaceAll(',', '.').trim();
  if (clean.isEmpty) return 0;
  var dots = 0;
  var digits = 0;
  for (var i = 0; i < clean.length; i++) {
    final c = clean[i];
    if (c == '.') {
      dots++;
    } else if ('0123456789'.contains(c)) {
      digits++;
    } else {
      return 0;
    }
  }
  if (dots > 1 || digits == 0) return 0;
  final num n = double.parse(clean);
  if (n > 0) return n;
  return 0;
}

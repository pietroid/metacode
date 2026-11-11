// parseAmount: Parses typed money text ('12,50' or '12.50' or ' 7 ') to a
// number; 0 when invalid.


num parseAmount(String text) {
  final String t = text.trim().replaceAll(',', '.');
  final double? v = double.tryParse(t);
  if (v == null) return 0;
  if (v <= 0) return 0;
  return v;
}

// formatMoney: 4.5 -> "$4.50" (two decimals).

String formatMoney(num amount) {
  return '\$${amount.toStringAsFixed(2)}';
}

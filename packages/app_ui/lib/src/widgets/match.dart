import 'package:flutter/widgets.dart';

import '../ui.dart';

Widget buildMatch(Ui ui, Map<String, dynamic> p) {
  final value = ui.binding(p['value'])?.toString();
  final cases = p['cases'];
  if (cases is Map) {
    for (final entry in cases.entries) {
      if (entry.key.toString() == value) return ui.node(entry.value);
    }
  }
  return p['default'] == null ? const SizedBox.shrink() : ui.node(p['default']);
}

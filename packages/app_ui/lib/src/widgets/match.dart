import 'package:flutter/widgets.dart';

import '../fade_switch.dart';
import '../ui.dart';

Widget buildMatch(Ui ui, Map<String, dynamic> p) {
  final value = ui.binding(p['value'])?.toString();
  final cases = p['cases'];
  if (cases is Map) {
    for (final entry in cases.entries) {
      if (entry.key.toString() == value) {
        return fadeSwitch(
            ui.context, p['fade'], 'case ${entry.key}', ui.node(entry.value));
      }
    }
  }
  return fadeSwitch(ui.context, p['fade'], 'default',
      p['default'] == null ? const SizedBox.shrink() : ui.node(p['default']));
}

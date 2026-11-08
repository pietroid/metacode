import 'package:flutter/widgets.dart';

import '../fade_switch.dart';
import '../ui.dart';

Widget buildIf(Ui ui, Map<String, dynamic> p) {
  final on = ui.binding(p['condition']) == true;
  final child = on
      ? ui.node(p['then'])
      : p['else'] == null
          ? const SizedBox.shrink()
          : ui.node(p['else']);
  return fadeSwitch(ui.context, p['fade'], on, child);
}

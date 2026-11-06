import 'package:flutter/widgets.dart';

import '../ui.dart';

Widget buildIf(Ui ui, Map<String, dynamic> p) {
  if (ui.binding(p['condition']) == true) return ui.node(p['then']);
  return p['else'] == null ? const SizedBox.shrink() : ui.node(p['else']);
}

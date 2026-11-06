import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildTextButton(Ui ui, Map<String, dynamic> p) {
  final onPressed = ui.action(p['onPressed']);
  final label = ui.node(p['text']);
  if (p['icon'] == null) return TextButton(onPressed: onPressed, child: label);
  return TextButton.icon(
      onPressed: onPressed, icon: Icon(parseIcon(p['icon'])), label: label);
}

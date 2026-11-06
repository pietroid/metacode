import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildFilledButton(Ui ui, Map<String, dynamic> p) {
  final onPressed = ui.action(p['onPressed']);
  final label = ui.node(p['text']);
  if (p['icon'] == null) return FilledButton(onPressed: onPressed, child: label);
  return FilledButton.icon(
      onPressed: onPressed, icon: Icon(parseIcon(p['icon'])), label: label);
}

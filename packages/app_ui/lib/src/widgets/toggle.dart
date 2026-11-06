import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildToggle(Ui ui, Map<String, dynamic> p) {
  final value = ui.binding(p['value']) == true;
  final onChanged = ui.actionWithValue<bool>(p['onChanged']);
  if (p['label'] == null) return Switch(value: value, onChanged: onChanged);
  return SwitchListTile(
      value: value, onChanged: onChanged, title: ui.node(p['label']));
}

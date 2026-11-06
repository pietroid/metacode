import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildCheckbox(Ui ui, Map<String, dynamic> p) {
  final onChanged = ui.actionWithValue<bool?>(p['onChanged']);
  return Checkbox(value: ui.binding(p['value']) == true, onChanged: onChanged);
}

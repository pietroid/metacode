import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildDropdown(Ui ui, Map<String, dynamic> p) {
  final options = [
    for (final o in (ui.resolve(p['options']) as List? ?? const [])) o.toString(),
  ];
  final value = ui.binding(p['value'])?.toString();
  final onChanged = ui.actionWithValue<String>(p['onChanged']);
  return DropdownButton<String>(
    value: options.contains(value) ? value : null,
    hint: p['hint'] == null ? null : Text(p['hint'].toString()),
    isExpanded: true,
    items: [
      for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
    ],
    onChanged: onChanged == null
        ? null
        : (v) {
            if (v != null) onChanged(v);
          },
  );
}

import 'package:flutter/material.dart';

import '../parsers.dart';
import '../theme.dart';
import '../ui.dart';

/// A dropdown framed like a text field, so forms read as one system.
Widget buildDropdown(Ui ui, Map<String, dynamic> p) {
  final t = MetacodeTokens.of(ui.context);
  final text = Theme.of(ui.context).textTheme;
  final options = [
    for (final o in (ui.resolve(p['options']) as List? ?? const [])) o.toString(),
  ];
  final value = ui.binding(p['value'])?.toString();
  final onChanged = ui.actionWithValue<String>(p['onChanged']);
  return InputDecorator(
    isEmpty: !options.contains(value),
    decoration: const InputDecoration(
      contentPadding: EdgeInsets.fromLTRB(16, 12, 12, 12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: options.contains(value) ? value : null,
        hint: p['hint'] == null
            ? null
            : Text(p['hint'].toString(),
                style: text.bodyLarge!.copyWith(color: t.ink3)),
        isExpanded: true,
        isDense: true,
        style: text.bodyLarge,
        icon: Icon(parseIcon('expandMore', ui.context), size: 16, color: t.ink2),
        borderRadius: t.corners('md'),
        dropdownColor: t.surface,
        elevation: 4,
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: onChanged == null
            ? null
            : (v) {
                if (v != null) onChanged(v);
              },
      ),
    ),
  );
}

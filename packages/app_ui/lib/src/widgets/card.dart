import 'package:flutter/material.dart';

import '../parsers.dart';
import '../theme.dart';
import '../ui.dart';

/// A raised surface: lifted by a soft shadow in light mode, edged by a
/// hairline in dark mode. A tinted card (with `color`) sits flat.
Widget buildCard(Ui ui, Map<String, dynamic> p) {
  final t = MetacodeTokens.of(ui.context);
  final onTap = ui.action(p['onTap']);
  final color = parseColor(p['color'], ui.context);
  final corners = t.corners('md');
  final content = Padding(
    padding: parseEdgeInsets(p['padding']) ?? EdgeInsets.all(t.spacing['s5']!),
    child: ui.node(p['child']),
  );
  return DecoratedBox(
    decoration: BoxDecoration(
      color: color ?? t.surface,
      borderRadius: corners,
      boxShadow: color == null ? t.raised : null,
      border: color == null && t.dark ? Border.fromBorderSide(t.raisedEdge) : null,
    ),
    child: Material(
      type: MaterialType.transparency,
      borderRadius: corners,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    ),
  );
}

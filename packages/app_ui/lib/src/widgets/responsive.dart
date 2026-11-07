import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

/// Shows `wide` when the available width reaches `breakpoint`, else `narrow`.
Widget buildResponsive(Ui ui, Map<String, dynamic> p) {
  final breakpoint = parseDouble(p['breakpoint']) ?? 720;
  return LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= breakpoint;
      final node = wide ? (p['wide'] ?? p['narrow']) : (p['narrow'] ?? p['wide']);
      return ui.node(node);
    },
  );
}

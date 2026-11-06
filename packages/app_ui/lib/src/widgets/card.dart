import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildCard(Ui ui, Map<String, dynamic> p) {
  final onTap = ui.action(p['onTap']);
  final content = Padding(
    padding: parseEdgeInsets(p['padding']) ?? const EdgeInsets.all(16),
    child: ui.node(p['child']),
  );
  return Card(
    color: parseColor(p['color'], ui.context),
    clipBehavior: Clip.antiAlias,
    child: onTap == null ? content : InkWell(onTap: onTap, child: content),
  );
}

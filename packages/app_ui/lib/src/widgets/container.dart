import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildContainer(Ui ui, Map<String, dynamic> p) {
  final radius = parseDouble(p['radius']);
  return Container(
    padding: parseEdgeInsets(p['padding']),
    margin: parseEdgeInsets(p['margin']),
    width: parseDouble(p['width']),
    height: parseDouble(p['height']),
    clipBehavior: radius == null ? Clip.none : Clip.antiAlias,
    decoration: BoxDecoration(
      color: parseColor(p['color'], ui.context),
      borderRadius: radius == null ? null : BorderRadius.circular(radius),
    ),
    child: p['child'] == null ? null : ui.node(p['child']),
  );
}

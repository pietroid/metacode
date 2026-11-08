import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../theme.dart';
import '../ui.dart';

Widget buildContainer(Ui ui, Map<String, dynamic> p) {
  final radius = parseDouble(p['radius']);
  final borderColor = parseColor(p['borderColor'], ui.context);
  final maxWidth = parseDouble(p['maxWidth']);
  final opacity = parseDouble(p['opacity'])?.clamp(0.0, 1.0);
  final Widget plain = Container(
    padding: parseEdgeInsets(p['padding']),
    margin: parseEdgeInsets(p['margin']),
    width: parseDouble(p['width']),
    height: parseDouble(p['height']),
    clipBehavior: radius == null ? Clip.none : Clip.antiAlias,
    decoration: BoxDecoration(
      color: parseColor(p['color'], ui.context),
      borderRadius: radius == null ? null : BorderRadius.circular(radius),
      border: borderColor == null
          ? null
          : Border.all(color: borderColor, width: MetacodeTokens.of(ui.context).border),
    ),
    child: p['child'] == null ? null : ui.node(p['child']),
  );
  final box =
      opacity == null || opacity >= 1 ? plain : Opacity(opacity: opacity, child: plain);
  if (maxWidth == null) return box;
  return Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: box),
    ),
  );
}

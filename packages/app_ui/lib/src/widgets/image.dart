import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildImage(Ui ui, Map<String, dynamic> p) {
  final src = ui.resolve(p['src'])?.toString() ?? '';
  final width = parseDouble(p['width']);
  final height = parseDouble(p['height']);
  final fit = parseBoxFit(p['fit']);
  Widget fallback(_, _, _) => SizedBox(width: width, height: height);

  final Widget image = src.startsWith('http')
      ? Image.network(src,
          width: width, height: height, fit: fit, errorBuilder: fallback)
      : Image.asset(src,
          width: width, height: height, fit: fit, errorBuilder: fallback);

  final radius = parseDouble(p['radius']);
  if (radius == null) return image;
  return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
}

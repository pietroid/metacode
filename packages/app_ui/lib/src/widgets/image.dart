import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildImage(Ui ui, Map<String, dynamic> p) {
  final src = ui.resolve(p['src'])?.toString() ?? '';
  final width = parseDouble(p['width']);
  final height = parseDouble(p['height']);
  final fit = parseBoxFit(p['fit']);
  final empty = SizedBox(width: width, height: height);
  Widget fallback(_, _, _) => empty;

  final network = src.startsWith('http');
  final svg = Uri.tryParse(src)?.path.toLowerCase().endsWith('.svg') ?? false;
  final Widget image;
  if (svg) {
    image = network
        ? SvgPicture.network(src,
            width: width, height: height, fit: fit ?? BoxFit.contain,
            errorBuilder: fallback)
        : SvgPicture.asset(src,
            width: width, height: height, fit: fit ?? BoxFit.contain,
            errorBuilder: fallback);
  } else {
    image = network
        ? Image.network(src,
            width: width, height: height, fit: fit, errorBuilder: fallback)
        : Image.asset(src,
            width: width, height: height, fit: fit, errorBuilder: fallback);
  }

  final radius = parseDouble(p['radius']);
  if (radius == null) return image;
  return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
}

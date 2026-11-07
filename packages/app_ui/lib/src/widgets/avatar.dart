import 'package:flutter/material.dart';

import '../parsers.dart';
import '../theme.dart';
import '../ui.dart';

/// A round avatar (the style's `pill` radius): an image, or initials.
Widget buildAvatar(Ui ui, Map<String, dynamic> p) {
  final t = MetacodeTokens.of(ui.context);
  final image = ui.resolve(p['image'])?.toString();
  final text = ui.resolve(p['text'])?.toString();
  final radius = parseDouble(p['radius']) ?? 20;
  final color = parseColor(p['color'], ui.context) ?? t.fillStrong;
  final onColor = p['color'] == null
      ? t.ink2
      : ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : const Color(0xFF151514);
  final hasImage = image != null && image.startsWith('http');
  return Container(
    width: radius * 2,
    height: radius * 2,
    alignment: Alignment.center,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(
          t.radius['pill']!.clamp(0, radius).toDouble()),
      image: hasImage
          ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
          : null,
    ),
    child: text == null || hasImage
        ? null
        : Text(
            text,
            style: TextStyle(
              fontFamily: t.displayFamily,
              fontSize: radius * 0.66,
              fontWeight: FontWeight.w500,
              letterSpacing: radius * 0.01,
              color: onColor,
              height: 1,
            ),
          ),
  );
}

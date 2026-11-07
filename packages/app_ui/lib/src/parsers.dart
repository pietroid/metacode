import 'package:flutter/material.dart';

import 'icons.dart';
import 'theme.dart';

/// Parsers for literal property values shared by widget builders.
/// Allowed names are listed in spec.dart (iconNames, colorNames,
/// textVariants); test/catalog_test.dart keeps both sides in sync.

double? parseDouble(dynamic value) => (value as num?)?.toDouble();

/// Every color name ui.yaml can use, resolved for the current theme.
///
/// Style tokens (bg, ink, accent, success...) come straight from style.yaml.
/// Material scheme names are derived from the same tokens. Hue names (red,
/// green...) map to the style's tuned colors where one exists, so a quick
/// `color: red` still sits in the palette.
Map<String, Color> themeColors(BuildContext context) {
  final c = Theme.of(context).colorScheme;
  final t = MetacodeTokens.of(context);
  return {
    ...t.colors,
    'primary': c.primary,
    'onPrimary': c.onPrimary,
    'primaryContainer': c.primaryContainer,
    'onPrimaryContainer': c.onPrimaryContainer,
    'secondary': c.secondary,
    'onSecondary': c.onSecondary,
    'secondaryContainer': c.secondaryContainer,
    'onSecondaryContainer': c.onSecondaryContainer,
    'tertiary': c.tertiary,
    'surface': t.surface,
    'onSurface': c.onSurface,
    'onSurfaceVariant': c.onSurfaceVariant,
    'outline': c.outline,
    'error': c.error,
    'transparent': Colors.transparent,
    'white': Colors.white,
    'black': Colors.black,
    'grey': t.ink3,
    'red': t.color('danger'),
    'green': t.color('success'),
    'blue': t.color('info'),
    'orange': t.accent,
    'amber': t.color('warning'),
    'purple': Colors.purple.shade400,
    'pink': Colors.pink.shade400,
    'teal': Colors.teal.shade500,
  };
}

Color? parseColor(dynamic value, BuildContext context) {
  if (value is! String) return null;
  if (value.startsWith('#')) {
    final hex = value.substring(1);
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    return null;
  }
  return themeColors(context)[value];
}

FontWeight? parseFontWeight(dynamic value) => const {
      'bold': FontWeight.bold,
      'normal': FontWeight.normal,
      'w100': FontWeight.w100,
      'w200': FontWeight.w200,
      'w300': FontWeight.w300,
      'w400': FontWeight.w400,
      'w500': FontWeight.w500,
      'w600': FontWeight.w600,
      'w700': FontWeight.w700,
      'w800': FontWeight.w800,
      'w900': FontWeight.w900,
    }[value];

Map<String, TextStyle?> textVariantStyles(BuildContext context) {
  final t = Theme.of(context).textTheme;
  return {
    'displayLarge': t.displayLarge,
    'displayMedium': t.displayMedium,
    'displaySmall': t.displaySmall,
    'headlineLarge': t.headlineLarge,
    'headlineMedium': t.headlineMedium,
    'headlineSmall': t.headlineSmall,
    'titleLarge': t.titleLarge,
    'titleMedium': t.titleMedium,
    'titleSmall': t.titleSmall,
    'bodyLarge': t.bodyLarge,
    'bodyMedium': t.bodyMedium,
    'bodySmall': t.bodySmall,
    'labelLarge': t.labelLarge,
    'labelMedium': t.labelMedium,
    'labelSmall': t.labelSmall,
  };
}

TextStyle? parseTextStyle(dynamic style, BuildContext context) {
  if (style is! Map) return null;
  final base = textVariantStyles(context)[style['variant']] ?? const TextStyle();
  return base.copyWith(
    fontSize: parseDouble(style['fontSize']),
    fontWeight: parseFontWeight(style['fontWeight']),
    color: parseColor(style['color'], context),
    fontStyle: style['italic'] == true ? FontStyle.italic : null,
  );
}

TextAlign? parseTextAlign(dynamic value) => const {
      'left': TextAlign.left,
      'center': TextAlign.center,
      'right': TextAlign.right,
    }[value];

/// The icon for a ui.yaml icon name, in the style's icon weight.
IconData parseIcon(dynamic name, BuildContext context) =>
    phosphorIcons[MetacodeTokens.of(context).iconWeight]![name] ??
    fallbackIcon;

/// The filled form of an icon, for selected states (e.g. the current tab).
IconData parseSelectedIcon(dynamic name) =>
    phosphorIcons['fill']![name] ?? fallbackIcon;

MainAxisAlignment parseMainAxisAlignment(dynamic value) => const {
      'start': MainAxisAlignment.start,
      'end': MainAxisAlignment.end,
      'center': MainAxisAlignment.center,
      'spaceBetween': MainAxisAlignment.spaceBetween,
      'spaceAround': MainAxisAlignment.spaceAround,
      'spaceEvenly': MainAxisAlignment.spaceEvenly,
    }[value] ??
    MainAxisAlignment.start;

CrossAxisAlignment parseCrossAxisAlignment(dynamic value) => const {
      'start': CrossAxisAlignment.start,
      'end': CrossAxisAlignment.end,
      'center': CrossAxisAlignment.center,
      'stretch': CrossAxisAlignment.stretch,
    }[value] ??
    CrossAxisAlignment.center;

Alignment parseAlignment(dynamic value) => const {
      'topLeft': Alignment.topLeft,
      'topCenter': Alignment.topCenter,
      'topRight': Alignment.topRight,
      'centerLeft': Alignment.centerLeft,
      'center': Alignment.center,
      'centerRight': Alignment.centerRight,
      'bottomLeft': Alignment.bottomLeft,
      'bottomCenter': Alignment.bottomCenter,
      'bottomRight': Alignment.bottomRight,
    }[value] ??
    Alignment.topLeft;

BoxFit? parseBoxFit(dynamic value) => const {
      'cover': BoxFit.cover,
      'contain': BoxFit.contain,
      'fill': BoxFit.fill,
      'fitWidth': BoxFit.fitWidth,
      'fitHeight': BoxFit.fitHeight,
    }[value];

/// Padding from a number (all sides) or a map of
/// all/horizontal/vertical/left/right/top/bottom.
EdgeInsets? parseEdgeInsets(dynamic value) {
  if (value == null) return null;
  if (value is num) return EdgeInsets.all(value.toDouble());
  if (value is! Map) return null;
  if (value['all'] != null) return EdgeInsets.all(parseDouble(value['all'])!);
  final h = parseDouble(value['horizontal']);
  final v = parseDouble(value['vertical']);
  return EdgeInsets.only(
    left: parseDouble(value['left']) ?? h ?? 0,
    right: parseDouble(value['right']) ?? h ?? 0,
    top: parseDouble(value['top']) ?? v ?? 0,
    bottom: parseDouble(value['bottom']) ?? v ?? 0,
  );
}

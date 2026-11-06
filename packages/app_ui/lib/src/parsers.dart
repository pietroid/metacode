import 'package:flutter/material.dart';

/// Parsers for literal property values shared by widget builders.

double? parseDouble(dynamic value) => (value as num?)?.toDouble();

Color? parseColor(dynamic value) {
  if (value is! String) return null;
  final hex = value.replaceFirst('#', '');
  if (value.startsWith('#') && hex.length == 6) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  if (value.startsWith('#') && hex.length == 8) {
    return Color(int.parse(hex, radix: 16));
  }
  return const {
    'red': Colors.red,
    'green': Colors.green,
    'blue': Colors.blue,
    'black': Colors.black,
    'white': Colors.white,
    'grey': Colors.grey,
  }[value];
}

FontWeight? parseFontWeight(dynamic value) => const {
      'bold': FontWeight.bold,
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

TextStyle? parseTextStyle(dynamic style) {
  if (style is! Map) return null;
  return TextStyle(
    fontSize: parseDouble(style['fontSize']),
    fontWeight: parseFontWeight(style['fontWeight']),
    color: parseColor(style['color']),
  );
}

const icons = {
  'add': Icons.add,
  'delete': Icons.delete,
  'inbox': Icons.inbox,
  'check': Icons.check,
  'close': Icons.close,
};

IconData parseIcon(dynamic name) => icons[name] ?? Icons.circle;

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

EdgeInsets parsePadding(Map<String, dynamic> p) {
  if (p['all'] != null) return EdgeInsets.all(parseDouble(p['all'])!);
  final h = parseDouble(p['horizontal']);
  final v = parseDouble(p['vertical']);
  return EdgeInsets.only(
    left: parseDouble(p['left']) ?? h ?? 0,
    right: parseDouble(p['right']) ?? h ?? 0,
    top: parseDouble(p['top']) ?? v ?? 0,
    bottom: parseDouble(p['bottom']) ?? v ?? 0,
  );
}

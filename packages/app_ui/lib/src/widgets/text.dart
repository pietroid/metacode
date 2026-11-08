import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildText(Ui ui, Map<String, dynamic> p) {
  final style = parseTextStyle(p['style'], ui.context);
  final align = parseTextAlign(p['align']);
  final maxLines = p['maxLines'] as int?;
  final overflow = maxLines == null ? null : TextOverflow.ellipsis;
  final spans = p['spans'];
  if (spans is List) {
    return Text.rich(
      TextSpan(children: [
        for (final s in spans)
          TextSpan(
            text: ui.resolve(s is Map ? s['value'] : s)?.toString() ?? '',
            style: s is Map ? parseTextStyle(s['style'], ui.context) : null,
          ),
      ]),
      style: style,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
  final text = ui.resolve(p['value'])?.toString() ?? '';
  final reveal = parseDouble(p['reveal']);
  if (reveal != null && reveal < 1) {
    // The hidden rest is drawn transparent, so the text keeps its final
    // size while it types out.
    final shown = (text.length * reveal.clamp(0.0, 1.0)).round();
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: text.substring(0, shown)),
        TextSpan(
            text: text.substring(shown),
            style: const TextStyle(color: Color(0x00000000))),
      ]),
      style: style,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
  return Text(
    text,
    style: style,
    textAlign: align,
    maxLines: maxLines,
    overflow: overflow,
  );
}

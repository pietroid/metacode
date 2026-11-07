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
  return Text(
    ui.resolve(p['value'])?.toString() ?? '',
    style: style,
    textAlign: align,
    maxLines: maxLines,
    overflow: overflow,
  );
}

import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildWrap(Ui ui, Map<String, dynamic> p) => Wrap(
      spacing: parseDouble(p['spacing']) ?? 0,
      runSpacing: parseDouble(p['runSpacing']) ?? 0,
      alignment: switch (p['alignment']) {
        'center' => WrapAlignment.center,
        'end' => WrapAlignment.end,
        'spaceBetween' => WrapAlignment.spaceBetween,
        'spaceAround' => WrapAlignment.spaceAround,
        'spaceEvenly' => WrapAlignment.spaceEvenly,
        _ => WrapAlignment.start,
      },
      children: ui.nodes(p['children']),
    );

import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildColumn(Ui ui, Map<String, dynamic> p) => Column(
      mainAxisAlignment: parseMainAxisAlignment(p['mainAxisAlignment']),
      crossAxisAlignment: parseCrossAxisAlignment(p['crossAxisAlignment']),
      spacing: parseDouble(p['spacing']) ?? 0,
      children: ui.nodes(p['children']),
    );

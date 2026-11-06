import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildColumn(Ui ui, Map<String, dynamic> p) => Column(
      mainAxisAlignment: parseMainAxisAlignment(p['mainAxisAlignment']),
      crossAxisAlignment: parseCrossAxisAlignment(p['crossAxisAlignment']),
      children: ui.nodes(p['children']),
    );

import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildRow(Ui ui, Map<String, dynamic> p) => Row(
      mainAxisAlignment: parseMainAxisAlignment(p['mainAxisAlignment']),
      crossAxisAlignment: parseCrossAxisAlignment(p['crossAxisAlignment']),
      children: ui.nodes(p['children']),
    );

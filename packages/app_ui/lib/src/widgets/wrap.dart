import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildWrap(Ui ui, Map<String, dynamic> p) => Wrap(
      spacing: parseDouble(p['spacing']) ?? 0,
      children: ui.nodes(p['children']),
    );

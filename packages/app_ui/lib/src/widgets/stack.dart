import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildStack(Ui ui, Map<String, dynamic> p) => Stack(
      alignment: parseAlignment(p['alignment']),
      children: ui.nodes(p['children']),
    );

import 'package:flutter/widgets.dart';

import '../ui.dart';

Widget buildExpanded(Ui ui, Map<String, dynamic> p) => Expanded(
      flex: (p['flex'] as int?) ?? 1,
      child: ui.node(p['child']),
    );

import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildPadding(Ui ui, Map<String, dynamic> p) => Padding(
      padding: parseEdgeInsets(p) ?? EdgeInsets.zero,
      child: ui.node(p['child']),
    );

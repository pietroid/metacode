import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildFloatingActionButton(Ui ui, Map<String, dynamic> p) =>
    FloatingActionButton(
      onPressed: ui.action(p['onPressed']),
      child: p['icon'] != null ? Icon(parseIcon(p['icon'], ui.context)) : ui.node(p['child']),
    );

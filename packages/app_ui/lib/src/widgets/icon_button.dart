import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildIconButton(Ui ui, Map<String, dynamic> p) => IconButton(
      icon: Icon(parseIcon(p['icon'])),
      tooltip: p['tooltip']?.toString(),
      onPressed: ui.action(p['onPressed']),
    );

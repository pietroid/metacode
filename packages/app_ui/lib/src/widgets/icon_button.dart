import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildIconButton(Ui ui, Map<String, dynamic> p) => IconButton(
      icon: Icon(parseIcon(p['icon'], ui.context)),
      tooltip: ui.resolve(p['tooltip'])?.toString(),
      color: parseColor(p['color'], ui.context),
      onPressed: ui.action(p['onPressed']),
    );

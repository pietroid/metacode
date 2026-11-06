import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildDivider(Ui ui, Map<String, dynamic> p) => Divider(
      height: parseDouble(p['height']),
      color: parseColor(p['color'], ui.context),
    );

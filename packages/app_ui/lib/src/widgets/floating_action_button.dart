import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildFloatingActionButton(Ui ui, Map<String, dynamic> p) =>
    FloatingActionButton(
      onPressed: ui.action(p['onPressed']),
      child: ui.node(p['child']),
    );

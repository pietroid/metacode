import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildElevatedButton(Ui ui, Map<String, dynamic> p) => ElevatedButton(
      onPressed: ui.action(p['onPressed']),
      child: ui.node(p['child']),
    );

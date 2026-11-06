import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildTextButton(Ui ui, Map<String, dynamic> p) => TextButton(
      onPressed: ui.action(p['onPressed']),
      child: ui.node(p['text']),
    );

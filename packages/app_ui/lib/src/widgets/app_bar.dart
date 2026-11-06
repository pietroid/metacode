import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildAppBar(Ui ui, Map<String, dynamic> p) => AppBar(
      title: p['title'] == null ? null : ui.node(p['title']),
      actions: p['actions'] == null ? null : ui.nodes(p['actions']),
      backgroundColor: parseColor(p['backgroundColor']),
    );

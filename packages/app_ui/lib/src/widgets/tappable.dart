import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildTappable(Ui ui, Map<String, dynamic> p) =>
    InkWell(onTap: ui.action(p['onTap']), child: ui.node(p['child']));

import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildScaffold(Ui ui, Map<String, dynamic> p) {
  final appBar = p['appBar'];
  return Scaffold(
    appBar: appBar is Map
        ? ui.widget('appBar', Map<String, dynamic>.from(appBar)) as AppBar
        : null,
    body: p['body'] == null ? null : ui.node(p['body']),
    floatingActionButton: p['floatingActionButton'] == null
        ? null
        : ui.node(p['floatingActionButton']),
  );
}

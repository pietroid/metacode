import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildScaffold(Ui ui, Map<String, dynamic> p) {
  Widget? opt(String key) => p[key] == null ? null : ui.node(p[key]);
  final appBar = p['appBar'];
  return Scaffold(
    appBar: appBar is Map
        ? ui.widget('appBar', Map<String, dynamic>.from(appBar)) as AppBar
        : null,
    body: opt('body'),
    floatingActionButton: opt('floatingActionButton'),
    bottomNavigationBar: opt('bottomBar'),
  );
}

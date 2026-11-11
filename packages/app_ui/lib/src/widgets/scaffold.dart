import 'package:flutter/material.dart';

import '../ui.dart';
import 'navigation_bar.dart';

Widget buildScaffold(Ui ui, Map<String, dynamic> p) {
  Widget? opt(String key) => p[key] == null ? null : ui.node(p[key]);
  final appBar = p['appBar'];
  // A navigationBar written inline in bottomBar becomes a side rail on wide
  // screens.
  final bar = p['bottomBar'];
  final nav = bar is Map && bar['navigationBar'] is Map
      ? Map<String, dynamic>.from(bar['navigationBar'] as Map)
      : null;
  final breakpoint = nav == null ? null : railBreakpoint(nav);
  final rail = breakpoint != null &&
      MediaQuery.sizeOf(ui.context).width >= breakpoint;
  final body = opt('body');
  return Scaffold(
    appBar: appBar is Map
        ? ui.widget('appBar', Map<String, dynamic>.from(appBar)) as AppBar
        : null,
    body: rail
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildNavigationRail(ui, nav!),
              Expanded(child: body ?? const SizedBox.shrink()),
            ],
          )
        : body,
    floatingActionButton: opt('floatingActionButton'),
    bottomNavigationBar: rail ? null : opt('bottomBar'),
  );
}

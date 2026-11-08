import 'package:flutter/material.dart';

import '../parsers.dart';
import '../theme.dart';
import '../ui.dart';

Widget buildNavigationBar(Ui ui, Map<String, dynamic> p) {
  final t = MetacodeTokens.of(ui.context);
  final destinations = (p['destinations'] as List? ?? const [])
      .whereType<Map>()
      .map((d) => NavigationDestination(
            icon: Icon(parseIcon(d['icon'], ui.context)),
            selectedIcon: Icon(parseSelectedIcon(d['icon'])),
            label: ui.resolve(d['label'])?.toString() ?? '',
          ))
      .toList();
  final selected = ui.binding(p['selected']);
  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: t.line, width: t.border)),
    ),
    child: NavigationBar(
      destinations: destinations,
      selectedIndex: selected is num
          ? selected.toInt().clamp(0, destinations.length - 1)
          : 0,
      onDestinationSelected: ui.actionWithValue<int>(p['onSelected']),
    ),
  );
}

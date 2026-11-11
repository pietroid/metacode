import 'package:flutter/material.dart';

import '../parsers.dart';
import '../theme.dart';
import '../ui.dart';

/// The width from which [p] (a navigationBar's props) shows as a side rail;
/// null when it never does (`rail: false`).
double? railBreakpoint(Map<String, dynamic> p) {
  final rail = p['rail'];
  if (rail == false) return null;
  return rail is num ? rail.toDouble() : 840;
}

/// The navigationBar's destinations as a side rail, for wide screens (the
/// scaffold puts it left of the body).
Widget buildNavigationRail(Ui ui, Map<String, dynamic> p) {
  final t = MetacodeTokens.of(ui.context);
  final destinations = (p['destinations'] as List? ?? const [])
      .whereType<Map>()
      .map((d) => NavigationRailDestination(
            icon: Icon(parseIcon(d['icon'], ui.context)),
            selectedIcon: Icon(parseSelectedIcon(d['icon'])),
            label: Text(ui.resolve(d['label'])?.toString() ?? ''),
          ))
      .toList();
  final selected = ui.binding(p['selected']);
  final onSelected = ui.actionWithValue<int>(p['onSelected']);
  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border(right: BorderSide(color: t.line, width: t.border)),
    ),
    child: NavigationRail(
      labelType: NavigationRailLabelType.all,
      destinations: destinations,
      selectedIndex: destinations.isEmpty
          ? null
          : selected is num
              ? selected.toInt().clamp(0, destinations.length - 1)
              : 0,
      onDestinationSelected: onSelected,
    ),
  );
}

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

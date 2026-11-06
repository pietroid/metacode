import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildNavigationBar(Ui ui, Map<String, dynamic> p) {
  final destinations = (p['destinations'] as List? ?? const [])
      .whereType<Map>()
      .map((d) => NavigationDestination(
            icon: Icon(parseIcon(d['icon'])),
            label: d['label']?.toString() ?? '',
          ))
      .toList();
  final selected = ui.binding(p['selected']);
  return NavigationBar(
    destinations: destinations,
    selectedIndex: selected is num
        ? selected.toInt().clamp(0, destinations.length - 1)
        : 0,
    onDestinationSelected: ui.actionWithValue<int>(p['onSelected']),
  );
}

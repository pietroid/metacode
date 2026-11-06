import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildListTile(Ui ui, Map<String, dynamic> p) {
  Widget? opt(String key) => p[key] == null ? null : ui.node(p[key]);
  return ListTile(
    title: opt('title'),
    subtitle: opt('subtitle'),
    leading: opt('leading'),
    trailing: opt('trailing'),
    onTap: ui.action(p['onTap']),
  );
}

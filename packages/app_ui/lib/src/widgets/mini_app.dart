import 'package:flutter/widgets.dart';

import '../ui.dart';

Widget buildMiniApp(Ui ui, Map<String, dynamic> p) {
  final project = p['project'];
  if (project != null) return ui.dynamicModule(ui.binding(project));
  return ui.module('${p['module']}');
}
